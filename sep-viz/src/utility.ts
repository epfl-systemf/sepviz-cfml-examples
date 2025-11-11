/** Configuration Utilities */

import yaml from 'js-yaml';

export const resetKeywords = [
  'Goal',
  'Lemma',
  'Theorem',
  'Definition',
  'Example',
  'Corollary',
  '-',
  '+',
  '*',
  '{',
  '}',
];

export type AttrKey = string | number;
export type AttrValue = string | number | boolean;
export type Attrs = Record<AttrKey, AttrValue>;

export interface RenderConfig {
  font?: FontConfig;
  graph?: Attrs;
  edge?: Attrs;
  node?: Attrs;
  constr?: Record<string, ConstrConfig>;
}

export interface FontConfig {
  name?: string;
  size?: number;
  charwidth?: number;
  existVarColor?: string;
}

export interface ConstrConfig {
  inPorts?: string[];
  isFlat?: boolean;
  args?: Record<number, ArgConfig>;
}

export interface ArgConfig {
  inTable?: boolean;
  isPointer?: boolean;
  inPorts?: string[];
  outPorts?: string[];
}

export interface CompleteArgConfig {
  inTable: boolean;
  isPointer: boolean;
  inPorts: string[];
  outPorts: string[];
}

export async function loadRenderConfig(
  url = 'renderConfig.yaml'
): Promise<RenderConfig> {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to fetch ${url}: ${response.statusText}`);
  }
  const text = await response.text();
  return yaml.load(text) as RenderConfig;
}

/** HTML Utilities */

// Create a DOM element with given classes and optional text/id.
export function createElement(
  tag: keyof HTMLElementTagNameMap,
  classList: string[] = [],
  options: { text?: string; id?: string } = {}
): HTMLElement {
  const node = document.createElement(tag);
  classList.forEach((c) => node.classList.add(c));
  if (options.text) node.append(document.createTextNode(options.text));
  if (options.id) node.id = options.id;
  return node;
}

/** Graph algorithms */

type GraphNode = string | number | symbol;

export interface GraphEdge {
  src: GraphNode;
  dst: GraphNode;
}

export interface GraphNodeState {
  inStack: boolean;
  visited: boolean;
  longestDist: number;
  preEdgeIdx: number;
}

export type GraphState = Record<GraphNode, GraphNodeState>;

/**
 * DFS for cycle detection.
 * Side effect: updates longest-distance and predecessor info for each node.
 */
function isCircleDfs(
  cur: GraphNode,
  edges: GraphEdge[],
  s: GraphState
): boolean {
  if (s[cur].inStack) return true;
  if (s[cur].visited) return false;
  s[cur].inStack = true;
  s[cur].visited = true;
  for (const [i, e] of edges.entries()) {
    if (e.src !== cur) continue;
    if (s[cur].longestDist + 1 > s[e.dst].longestDist) {
      s[e.dst].longestDist = s[cur].longestDist + 1;
      s[e.dst].preEdgeIdx = i;
    }
    if (isCircleDfs(e.dst, edges, s)) return true;
  }
  s[cur].inStack = false;
  return false;
}

/**
 * Return `[true, {}]` if there is a circle in the graph.
 * Otherwise, return `[false, s]` where `s: GraphState` holds the longest
 * distance information for each node.
 */
export function findCircleAndLongestDist(
  edges: GraphEdge[]
): [boolean, GraphState] {
  const nodes: GraphNode[] = [...new Set(edges.flatMap((e) => [e.src, e.dst]))];
  const s: GraphState = {};
  const isRoot: Record<GraphNode, boolean> = {};
  nodes.forEach((n) => {
    isRoot[n] = true;
    s[n] = { visited: false, inStack: false, longestDist: -1, preEdgeIdx: -1 };
  });
  edges.forEach((e) => {
    isRoot[e.dst] = false;
  });
  for (const n of nodes.filter((n) => isRoot[n])) {
    s[n].longestDist = 0;
    if (isCircleDfs(n, edges, s)) return [true, {}];
  }
  // If there is still any unvisited node, it must be inside a circle.
  for (const n of nodes) {
    if (!s[n].visited) return [true, {}];
  }
  return [false, s];
}
