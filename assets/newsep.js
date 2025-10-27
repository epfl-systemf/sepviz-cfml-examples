import * as SepParser from "./parser.js";
'use strict';

document.addEventListener("DOMContentLoaded", init);

const flatRepresentationPredicates = {
    'MNode': (formula) => [formula[1], formula[2]],
    'MCell': (formula) => [formula[1]],
}

const recursiveRepresentationPredicates = {
    'MList': (formula) => [formula[1]],
}

function parseHeapPredicate(hpred) {
    let objects = [];
    let purePredicates = [];
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

    function loop(hpred, ctx) {
        switch (hpred.kind) {
            case "stars":
                hpred.conjuncts.forEach(c => loop(c, ctx));
                break;
            case "existential":
                const num = next(hpred.binder);
                ctx = ctx.set(hpred.binder, {
                    global: false,
                    uid: hpred.binder + "$" + num,
                    label: `?${hpred.binder}${num}` // ['font', {}, `?${hpred.binder}`, ['sub', {}, `${num}`]]
                });
                loop(hpred.body, ctx);
                break;
            case "pointsTo":
                const addr = resolve(hpred.from, ctx);
                const [constr, ...args] = hpred.to;
                objects.push({
                    addr,
                    constr,
                    args: args.map(a => resolve(a, ctx))
                });
                break;
            case "gc":
                break;
            case "purePredicate":
                const predicate = hpred.predicate.map(x => ctx.has(x) ? resolve(x, ctx) : x);
                purePredicates.push(predicate);
                break;
            default:
                throw new Error("Not supported kind: ${hpred.kind}");
        }
    }

    loop(hpred, Immutable.Map({}));
    return {objects: objects, purePredicates: purePredicates};
}

function parse(term) {
    let string = [], stack = [];
    var res;
    SepParser.parse(term).forEach(x => {
        if (typeof x === 'object' && 'raw' in x) {
            stack.push(string.join(""));
            res = parseHeapPredicate(x.parsed);
            stack.push({ raw: x.raw, objects: res.objects, purePredicates: res.purePredicates });
            string = [];
        } else {
            string.push(x);
        }
    });
    stack.push(string.join(""));
    return stack;
}

// Put all pure predicates in a box.
function renderPurePredicates(purePredicates) {
    const host = document.createElement("div");
    host.className = "sep-pure-predicate-container";
    purePredicates.forEach(predicate => {
        let predicateNode = document.createElement("div");
        predicateNode.className = "sep-pure-predicate";
        predicate.forEach((part, index) => {
            if (index != 0)
                predicateNode.appendChild(document.createTextNode(" "));
            const partNode = document.createElement("span");
            if (typeof part === "object" && 'label' in part) {
                partNode.textContent = part.label;
                partNode.className = "sep-exist-var";
            } else {
                partNode.textContent = part;
            }
            predicateNode.appendChild(partNode);
        });
        host.appendChild(predicateNode);
    });
    return host;
}

function renderHeapObjectsInOneDiagram(objects) {
}

function init() {
    document.querySelectorAll(".goal-conclusion, .coq-message, .goal-hyp")
        .forEach(goal => {
            const parseResult = parse(goal.innerText);
            goal.innerText = "";
            // console.log("parseResult = ", parseResult);
            parseResult.forEach(parseUnit => {
                if (typeof parseUnit === 'object' && 'raw' in parseUnit) {
                    const host = document.createElement("span");
                    host.className = "sep-graph";
                    goal.append(host);
                    if(parseUnit.purePredicates.length > 0) {
                        host.append(renderPurePredicates(parseUnit.purePredicates));
                    }
                    host.append(renderHeapObjectsInOneDiagram(parseUnit.objects));
                } else {
                    goal.append(parseUnit);
                }
            });
        });
}
