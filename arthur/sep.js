'use strict';

// SepParser = require("./parser.node.js");
// Immutable = require('immutable');
// util = require('util');
// example = require("./example.js");
// console.log(util.inspect(render(example), { depth: null }));

// function stringp(x) {
//     return typeof x === 'string' || x instanceof String;
// }

function parse_sep(sep) {
    let objects = [];
    let gensym = {};

    function next(prefix) {
        if (!(prefix in gensym))
            gensym[prefix] = 0;
        return gensym[prefix]++;
    }

    function resolve(name, ctx) {
        return ctx.get(name, {
            global: true,
            uid: name,
            label: name
        });
    }

    function loop(sep, ctx) {
        switch (sep.kind) {
        case "stars":
            sep.conjuncts.forEach(c => loop(c, ctx));
            break;
        case "existential":
            const num = next(sep.binder);
            ctx = ctx.set(sep.binder, {
                global: false,
                uid: sep.binder + "$" + num,
                label: `?${sep.binder}${num}`
            });
            loop(sep.body, ctx);
            break;
        case "points-to":
            const addr = resolve(sep.from, ctx);
            const [constr, ...args] = sep.to;
            objects.push({
                addr,
                constr,
                args: args.map(a => resolve(a, ctx))
            });
            break;
        case "gc":
            break;
        }
    }

    loop(sep, Immutable.Map({}));
    return objects;
}

function parse(term) {
    let string = [], stack = [];
    SepParser.parse(term).forEach(x => {
        if (typeof x === 'object' && 'raw' in x) {
            stack.push(string.join(""));
            stack.push({ raw: x.raw, objects: parse_sep(x.parsed) });
            string = [];
        } else {
            string.push(x);
        }
    });
    stack.push(string.join(""));
    return stack;
}

function graphviz_input_ports_of_object(obj) {
    switch (obj.constr) {
    case "MCell":
        return { [obj.addr.uid]: ["car_in"] };
    case "MListSeg":
    case "MList":
    case "MQueue":
        return { [obj.addr.uid]: ["list"] };
    default:
        console.error("Unrecognized object:", obj);
        return { [obj.addr.uid]: [] };
    }
}

var SepFontInfo = {
    name: "Iosevka",
    size: 12.0,
    charwidth: 6.875,
}

function graphviz_label_of_object(obj, known_uids) {
    const xml = (node, default_attrs={}) => (attrs, ...contents) =>
          [node, { ...default_attrs, ...attrs}, ...contents];

    const table = xml('table', { border: 0,
                                 cellborder: 1,
                                 cellspacing: 0,
                                 cellpadding: 2 }),
          tr = xml('tr'), td = xml('td'), font = xml('font');

    // A hack because Viz.js has incorrect font metrics
    // See https://github.com/mdaines/viz.js/wiki/Caveats
    const centered = (v, fontsize=12.0) => {
        const width = fontsize / SepFontInfo.size * SepFontInfo.charwidth * v.length;
        return table({ border: 0,
                       cellborder: 0,
                       cellspacing: 0,
                       cellpadding: 0,
                       fixedsize: true,
                       width }, // FIXME also compute the height?
                     tr({}, td({}, v)));
    };

    const header =
          tr({}, td({ colspan: 2, cellpadding: 0, sides: "b" },
                    font({ ['point-size']: 8 },
                         centered(obj.constr, 8))));

    const value = (port, val) =>
          tr({}, td({ port, colspan: 2 },
                    centered(val.label)));

    const value_null = (port) =>
          tr({}, td({ port, colspan: 2 },
                    centered("∅")));

    const pointer = (port_in, port_out, ptr) =>
          tr({},
             td({ port: port_in, sides: "tlb" }, centered(ptr.label)),
             td({ port: port_out, sides: "trb" }, centered("⏺")));

    const value_or_ptr = (port_in, port_out, v) =>
          (v.uid in known_uids ?
           pointer(port_in, port_out, v) :
           (v.label == "null" && v.global ?
            value_null(port_in) : value(port_in, v)));

    switch (obj.constr) {
    case "MCell":
        return table({}, header,
                     value_or_ptr("car_in", "car_out", obj.args[0]),
                     value_or_ptr("cdr_in", "cdr_out", obj.args[1]));
    case "MListSeg":
        return table({ cellborder: 0 }, header,
                     value("list", obj.args[1]));
    case "MList":
    case "MQueue":
        return table({ cellborder: 0 }, header,
                     value("list", obj.args[0]));
    default:
        console.error("Unrecognized object:", obj);
        return table({}, header, ...obj.args.map(a => value(null, a)));
    }
}

function graphviz_node_of_object(obj, idx, known_uids) {
    return {
        name: obj.addr.uid, idx,
        props: { label: graphviz_label_of_object(obj, known_uids) }
    };
}

function graphviz_edges_of_object(obj, input_port_of_uid) {
    const name = obj.addr.uid;

    const cell_edge = (out_port, uid) => {
        const in_port = input_port_of_uid[uid];
        return in_port === undefined ?
            [] : [{ src: [name, ...out_port], dst: [uid, ...in_port, "w"] }];
    };

    switch (obj.constr) {
    case "MCell":
        return [...cell_edge(["car_out", "c"], obj.args[0].uid),
                ...cell_edge(["cdr_out", "c"], obj.args[1].uid)];
    case "MListSeg":
        // TODO: later code should handle the case where v doesn't exist
        const uid = obj.args[0].uid;
        const in_port = input_port_of_uid[uid] || [];
        return { src: [name, "list", "e"],
                 dst: [uid, ...in_port, "w"],
                 props: { tailclip: true } };
    case "MList":
    case "MQueue":
        return [];
    default:
        console.error("Unrecognized object:", obj);
        return [].concat(...obj.args.map(a => cell_edge([], a.uid)));
    }
}

function graphviz_pointers_of_object(obj, input_port_of_uid, has_incoming_edges) {
    if (obj.addr.global && !has_incoming_edges[obj.addr.uid]) {// (!) {
        const in_port = input_port_of_uid[obj.addr.uid] || [];
        const ptr_node = obj.addr.uid + '$ptr';
        return  { nodes: [{ name: ptr_node,
                            props: { label: obj.addr.label,
                                     fontsize: 10,
                                     width: 0 } }],
                  edges: [{ src: [ptr_node, "e"],
                            dst: [obj.addr.uid, ...in_port, "nw"],
                            props: { tailclip: true, minlen: 1 } }] };
    } else {
        return { nodes: [], edges: [] };
    }
}


function graphviz_elements_of_objects(objects) {
    const input_port_of_uid =
          Object.assign({}, ...objects.map(graphviz_input_ports_of_object));
    const nodes = objects.map((o, idx) =>
        graphviz_node_of_object(o, idx, input_port_of_uid));
    const edges =
          [].concat(...objects.map(o => graphviz_edges_of_object(o, input_port_of_uid)));

    let has_incoming_edges = {};
    edges.forEach(({ dst }) => has_incoming_edges[dst[0]] = true);
    objects.forEach(o => {
        let { nodes: ns, edges: es } = graphviz_pointers_of_object(o, input_port_of_uid, has_incoming_edges);
        nodes.push(...ns);
        edges.push(...es);
    });
    // TODO: https://graphviz.org/doc/info/attrs.html#a:sortv explains how packmode can be used to preserve the order of the clusters
    // TODO: Add one graph per connected component, use HTML+CSS do the layout as inline-blocks (see ccomps)
    const props = [
        { target: "graph", props: {
            rankdir: "LR",
            ranksep: 0.1,
            nodesep: 0.2,
            concentrate: false,
            splines: true,
            packmode: "array",
            truecolor: true,
            fontsize: 12,
            width: 12,
            bgcolor: "#00000000" } },
        { target: "edge", props: {
            fontname: SepFontInfo.name,
            tailclip: false,
            arrowsize: 0.5,
            minlen: 3 } },
        { target: "node", props: {
            shape: "plaintext",
            fontname: SepFontInfo.name } }
    ];

    return [...props, ...nodes, ...edges];
}

function graphviz_render_text(graph_name, elements) {
    const map_dict = (attrs, fn) =>
          Object.entries(attrs).filter(v => v[1] !== null).map(fn);

    const render_attr = ([k, v]) =>
          v === null ? `` : ` ${k}="${v}"`;

    const render_attrs = (attrs) =>
          map_dict(attrs, render_attr).join("");

    const render_xml = (xml) => {
        if (Array.isArray(xml)) {
            const [node, attrs, ...contents] = xml;
            return [
                `<${node}${render_attrs(attrs)}>`,
                ...contents.map(render_xml),
                `</${node}>`
            ].join("");
        } else {
            return xml;
        }
    };

    const render_prop = ([k, v]) =>
          (k == "label" ?
           `${k}=<${render_xml(v)}>` :
           `${k}="${v}"`);

    const render_props = (props={}) =>
          "[" + map_dict(props, render_prop).join(", ") + "]";

    const render_extremity = (path) =>
          path.map(a => `"${a}"`).join(':');

    const render_one = (obj) => {
        if ("target" in obj)
            return `${obj.target} ${render_props(obj.props)}`;
        else if ("name" in obj)
            return `"${obj.name}" ${render_props(obj.props)}`;
        else if ("src" in obj)
            return `${render_extremity(obj.src)} -> ${render_extremity(obj.dst)} ${render_props(obj.props)}`;
        console.error("Unrecognized GraphViz construct:", obj);
        return "";
    };


    return [`digraph ${JSON.stringify(graph_name)} {`,
            ...elements.map(render_one),
            "}"].join("\n");
}

var viz = new Viz();

function render_graphviz(container, fragment) {
    const graph = graphviz_elements_of_objects(fragment.objects);
    const dot = graphviz_render_text(fragment.raw, graph);
    viz.renderSVGElement(dot)
        .then(element => container.append(element))
        .catch(error => {
            // https://github.com/mdaines/viz.js/wiki/Caveats
            viz = new Viz();
            console.error(error);
        });
    return dot;
}

function render_embedded() {
    document.querySelectorAll(".goal-conclusion").forEach(goal => {
        const _goal = goal.cloneNode(false);
        goal.parentNode.replaceChild(_goal, goal);

        parse(goal.innerText).forEach(fragment => {
            if (typeof fragment === 'object' && 'raw' in fragment) {
                const graph_node = document.createElement('span');
                const src_node = document.createElement('span');
                const dot_node = document.createElement('span');

                const dot_text = render_graphviz(graph_node, fragment);
                src_node.append(document.createTextNode(fragment.raw));
                dot_node.append(document.createTextNode(dot_text));

                const views = [graph_node, src_node, dot_node];
                _goal.append(graph_node);

                const onclick = () => {
                    _goal.replaceChild(views[1], views[0]);
                    views.push(views.shift());
                };
                views.forEach(v => {
                    v.className = "sep-graph";
                    v.onclick = onclick;
                    v.title = fragment.raw;
                });
            } else {
                _goal.append(document.createTextNode(fragment));
            }
        });
    });
}

render_embedded();
