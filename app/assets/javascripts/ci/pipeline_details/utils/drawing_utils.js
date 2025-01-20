import * as d3 from 'd3';
import { sankey, sankeyLeft } from 'd3-sankey';

/*
    createSankey calls the d3 layout to generate the relationships and positioning
    values for the nodes and links in the graph.
  */

export const createSankey = ({
  width = 10,
  height = 10,
  nodeWidth = 10,
  nodePadding = 10,
  paddingForLabels = 1,
} = {}) => {
  const sankeyGenerator = sankey()
    .nodeId(({ name }) => name)
    .nodeAlign(sankeyLeft)
    .nodeWidth(nodeWidth)
    .nodePadding(nodePadding)
    .extent([
      [paddingForLabels, paddingForLabels],
      [width - paddingForLabels, height - paddingForLabels],
    ]);
  return ({ nodes, links }) =>
    sankeyGenerator({
      nodes: nodes.map((d) => ({ ...d })),
      links: links.map((d) => ({ ...d })),
    });
};

export const createUniqueLinkId = (stageName, jobName) => `${stageName}-${jobName}`;

/**
 * This function expects its first argument data structure
 * to be the same shaped as the one generated by `parseData`,
 * which contains nodes and links. For each link,
 * we find the nodes in the graph, calculate their coordinates and
 * trace the lines that represent the needs of each job.
 * @param {Object} nodeDict - Resulting object of `parseData` with nodes and links
 * @param {String} containerID - Id for the svg the links will be draw in
 * @returns {Array} Links that contain all the information about them
 */

export const generateLinksData = (links, containerID, modifier = '') => {
  const containerEl = document.getElementById(containerID);

  return links.map((link) => {
    const path = d3.path();

    const sourceId = link.source;
    const targetId = link.target;

    const modifiedSourceId = `${sourceId}${modifier}`;
    const modifiedTargetId = `${targetId}${modifier}`;

    const sourceNodeEl = document.getElementById(modifiedSourceId);
    const targetNodeEl = document.getElementById(modifiedTargetId);

    const sourceNodeCoordinates = sourceNodeEl.getBoundingClientRect();
    const targetNodeCoordinates = targetNodeEl.getBoundingClientRect();
    const containerCoordinates = containerEl.getBoundingClientRect();

    // Because we add the svg dynamically and calculate the coordinates
    // with plain JS and not D3, we need to account for the fact that
    // the coordinates we are getting are absolutes, but we want to draw
    // relative to the svg container, which starts at `containerCoordinates(x,y)`
    // so we substract these from the total. We also need to remove the padding
    // from the total to make sure it's aligned properly. We then make the line
    // positioned in the center of the job node by adding half the height
    // of the job pill.
    const paddingLeft = parseFloat(
      window.getComputedStyle(containerEl, null).getPropertyValue('padding-left') || 0,
    );
    const paddingTop = parseFloat(
      window.getComputedStyle(containerEl, null).getPropertyValue('padding-top') || 0,
    );

    const sourceNodeX = sourceNodeCoordinates.right - containerCoordinates.x - paddingLeft;
    const sourceNodeY =
      sourceNodeCoordinates.top -
      containerCoordinates.y -
      paddingTop +
      sourceNodeCoordinates.height / 2;
    const targetNodeX = targetNodeCoordinates.x - containerCoordinates.x - paddingLeft;
    const targetNodeY =
      targetNodeCoordinates.y -
      containerCoordinates.y -
      paddingTop +
      sourceNodeCoordinates.height / 2;

    const sourceNodeLeftX = sourceNodeCoordinates.left - containerCoordinates.x - paddingLeft;

    // If the source and target X values are the same,
    // it means the nodes are in the same column so we
    // want to start the line on the left of the pill
    // instead of the right to have a nice curve.
    const firstPointCoordinateX = sourceNodeLeftX === targetNodeX ? sourceNodeLeftX : sourceNodeX;

    // First point
    path.moveTo(firstPointCoordinateX, sourceNodeY);

    // Make cross-stages lines a straight line all the way
    // until we can safely draw the bezier to look nice.
    // The adjustment number here is a magic number to make things
    // look nice and should change if the padding changes. This goes well
    // with gl-px-9 which we translate with 100px here.
    const straightLineDestinationX = targetNodeX - 100;
    const controlPointX = straightLineDestinationX + (targetNodeX - straightLineDestinationX) / 2;

    if (straightLineDestinationX > firstPointCoordinateX) {
      path.lineTo(straightLineDestinationX, sourceNodeY);
    }

    // Add bezier curve. The first 4 coordinates are the 2 control
    // points to create the curve, and the last one is the end point (x, y).
    // We want our control points to be in the middle of the line
    path.bezierCurveTo(
      controlPointX,
      sourceNodeY,
      controlPointX,
      targetNodeY,
      targetNodeX,
      targetNodeY,
    );

    return {
      ...link,
      source: sourceId,
      target: targetId,
      ref: createUniqueLinkId(sourceId, targetId),
      path: path.toString(),
    };
  });
};
