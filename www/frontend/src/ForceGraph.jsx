import React, {Component} from 'react';
import * as d3 from "d3";
import styled from 'styled-components';

const StyledResults = styled.div`
    height: 100%;
    .tableTitle {
        margin-top: 20px;
        text-align: center;
    }
`;

const SVG = styled.svg`
    width: 100%;
    height: 100%;

    .links line {
      stroke: #888;
      stroke-width: 6;
    }

    .nodes circle {
      pointer-events: all;
      stroke: none;
      stroke-width: 15px;
      cursor: pointer;
    }

    #limitButton {
        padding: 5px 10px;
        border: 1px solid #AAA;
        width: 100px;
        text-align: center;
        cursor: pointer;
        background-color: #DEDEDE;
        pointer-events: auto;
        position: absolute;
        bottom: 7px;
        left: 7px;
    }

    #utilizationButton {
        position: absolute;
        padding: 5px 10px;
        border: 1px solid #AAA;
        width: 100px;
        text-align: center;
        cursor: pointer;
        background-color: #DEDEDE;
        pointer-events: auto;
        bottom: 7px;
        right: 7px;
    }

    select {
        position: absolute;
        top: 7px;
        left: 7px;
        -webkit-appearance: button;
        -webkit-border-radius: 2px;
        -webkit-box-shadow: 0px 1px 3px rgba(0, 0, 0, 0.1);
        -webkit-padding-end: 20px;
        -webkit-padding-start: 2px;
        -webkit-user-select: none;
        background-image: url(http://i62.tinypic.com/15xvbd5.png), -webkit-linear-gradient(#FAFAFA, #F4F4F4 40%, #E5E5E5);
        background-position: 97% center;
        background-repeat: no-repeat;
        border: 1px solid #AAA;
        color: #555;
        overflow: hidden;
        padding: 5px 35px 5px 10px;
        text-overflow: ellipsis;
        white-space: nowrap;
        pointer-events: auto;
    }
`

const ScenarioTable = styled.table`
    border: 1px solid steelblue;
    background-color: rgba(255, 255, 255, .2);
    float: left;
    pointer-events: auto;

    th {
        padding: 3px 10px;
    }

    tr {
        cursor: pointer;
    }

    td {
        padding: 5px 10px;
        text-align: center;
    }

    .table-scroll {
        height: 200px;
        overflow: scroll;
    }

    .selected {
        background-color: rgba(200, 200, 200, .6);
    }
`;

const PathTable = styled.table`
    border: 1px solid steelblue;
    background-color: rgba(255, 255, 255, .2);
    float: right;
    pointer-events: auto;

    th {
        padding: 3px 10px;
    }

    tr {
        cursor: pointer;
    }

    td {
        padding: 5px 10px;
        text-align: center;
    }

    .selected {
        background-color: rgba(200, 200, 200, .6);
    }
`;

const OuterTable = styled.table`
    font-size: 14px;
    color: white;
    background-color: #444;
    border-radius: 10px;
    margin: 30px auto;

    tr {
        border: 1px solid gray;
    td {
        padding: 10px;
    }
    .border-bottom {
        border-bottom: 1px solid white;
        padding: 6px 0px;
    }
    .border-right {
        border-right: 1px solid white;
        padding: 0px 6px;
    }
`;

let colors = ["#1abc9c", "#3498db", "#9b59b6", "#34495e", "#e67e22", "#f1c40f"];
let dashes = ["5,5", "10,10", "20, 20", "20,10,5,5,5,10", "10,10,5,10"]

class ForceGraph extends Component {
    constructor(props){
        super(props)
        this.state = {
            simulation: "",
            numSelected: 0,
            firstSelected: null,
            secondSelected: null,
            nodeSize: 9,
            edgeLength: 100,
            flows: [],
            allocation: [],
            showPaths: false,
            showUtilization: 0,
            edgesByTunnel: [],
            nodesByTunnel: [],
            tunnelIndex: 0,
            scenario: 0,
            downLinks: [],
            dashLinks: [],
            colorNodes: [],
            secondaryNodes: [],
            secondaryTunnels: [],
            scenarios: [],
            capacity: [],
            failure_probabilities: [],
            linkUtilization: [],
            flowid: null,
            backFlowid: null,
            tips: [],
            graph: null,
            num_nodes: 0,
            limitTraffic: true,
        }
        this.click = this.click.bind(this);
        this.arrowPress = this.arrowPress.bind(this);
        this.dragstarted = this.dragstarted.bind(this);
        this.dragged = this.dragged.bind(this);
        this.dragended = this.dragended.bind(this);
        this.changeTunnel = this.changeTunnel.bind(this);
        this.showUtilization = this.showUtilization.bind(this);

    }

    componentDidMount() {
        this.drawGraph(this.props.topology)
    }

    componentWillReceiveProps(props) {
        this.clearGraph();
        this.drawGraph(props.topology);
        this.setState({
            num_nodes: props.num_nodes,
            f: props.flows,
            T: props.T,
            Tf: props.Tf,
            links: props.links,
            allocation: props.allocation,
            demand: props.demand,
            probabilities: props.probabilities,
            scenarios: props.scenarios,
            scenario: 0,
            showUtilization: 0,
            capacity: props.capacity,
            failure_probabilities: props.failure_probabilities,
            flowid: null,
            downLinks: [],
            X: props.X,
            var: props.var,
            cvar: props.cvar,
            limitTraffic: true,
            linkUtilization: [],
        }, () => {
            this.simulateTraffic();
            // let flows = {}
            // props.flows.forEach((nodes, flowid) => {
            //     let tunnels = this.getTunnels(flowid, nodes[0], nodes[1]);
            //     flows[flowid] = {
            //         id: flowid,
            //         src: nodes[0].toString(),
            //         dst: nodes[1].toString(),
            //         tunnels: tunnels,
            //         demand: props.demand[flowid],
            //         permissable: 1 - props.var,
            //     };
            // })
            // let satisfiedDemand = [];
            // if (props.scenarios) {
            //     let totalDemand = props.demand.reduce((i, j) => i + j);
            //     props.scenarios.forEach((scenario, s) => {
            //         let sentTraffic = this.state.graph ? new Array(this.state.graph.links.length).fill(0) : [];
            //         let satisfied = 0;
            //         Object.values(flows).forEach((flow, f) => {
            //             let total_weight = 0;
            //             let numAvailable = 0;
            //             flow.tunnels.forEach((tunnel, t) => {
            //                 total_weight += props.X[s][tunnel.id] === 1 ? this.state.allocation[f][t] : 0;
            //                 numAvailable += props.X[s][tunnel.id] === 1 ? 1 : 0;
            //             });
            //             flow.tunnels.forEach((tunnel, t) => {
            //                 let weight = 0
            //                 if (props.X[s][tunnel.id] === 1) {
            //                     weight = total_weight !== 0 ?
            //                             (this.state.allocation[f][t] / total_weight)  :
            //                             (1 / numAvailable);
            //                 } else {
            //                     weight = 0;
            //                 }
            //                 let congested = false;
            //                 tunnel.links.forEach(link => {
            //                     // let ls = this.state.graph.links.filter((l, index) => index === link.index);
            //                     if (sentTraffic[link.index] >= this.state.capacity[link.index]) {
            //                         congested = true;
            //                     }
            //                 })
            //                 if (!congested) {
            //                     tunnel.links.forEach(link => {
            //                         sentTraffic[link.index] += weight * flow.demand * flow.permissable
            //                     });
            //                     satisfied += weight * flow.demand * flow.permissable
            //                 }
            //             })
            //         })
            //         satisfiedDemand.push(satisfied / totalDemand)
            //     });
            // };
            // this.setState({
            //     flows,
            //     scenarioSatisfaction: satisfiedDemand,
            // }, this.updateGraph)
        });
    }

    componentDidUpdate(state) {
        // this.drawGraph()
    }

    simulateTraffic() {
        console.log(this.state);
        let flows = {}
        this.state.f.forEach((nodes, flowid) => {
            flows[flowid] = {
                id: flowid,
                src: nodes[0].toString(),
                dst: nodes[1].toString(),
                demand: this.state.demand[flowid],
                permissable: this.state.limitTraffic ? 1 - this.state.var : 1,
            };
        })
        let scenarioSatisfaction = [];
        let linkUtilization = new Array(this.state.capacity.length).fill(0);
        if (this.state.scenarios) {
            let totalDemand = this.state.demand.reduce((i, j) => i + j);
            this.state.scenarios.forEach((scenario, s) => {
                let scenarioSentTraffic = this.state.graph ? new Array(this.state.graph.links.length).fill(0) : [];
                let satisfiedDemandForScenario = 0;
                Object.values(flows).forEach((flow, f) => {
                    let satisfiedDemandForFlow = 0;
                    let flowTunnels = this.getTunnels(flow.id, flow.src, flow.dst, s);
                    flowTunnels.forEach((tunnel, t) => {
                        let weight = tunnel.weight;
                        let sent = weight * flow.demand * flow.permissable;

                        let congested = false;
                        let minSpace = Math.max(...this.state.capacity);
                        tunnel.links.forEach(link => {
                            minSpace = Math.min(minSpace, this.state.capacity[link.index] - scenarioSentTraffic[link.index])
                            if (scenarioSentTraffic[link.index] + sent > this.state.capacity[link.index]) {
                                congested = true;
                            }
                        })

                        if (!congested) {
                            tunnel.links.forEach(link => {
                                scenarioSentTraffic[link.index] += sent;
                                if (s === this.state.scenario) {
                                    linkUtilization[link.index] += sent;
                                }
                            });
                            if (s === this.state.scenario) {
                                tunnel.sent = sent;
                                satisfiedDemandForFlow += sent;
                            }
                            satisfiedDemandForScenario += sent;
                        } else if (minSpace > 0){
                            sent = minSpace;
                            tunnel.links.forEach(link => {
                                scenarioSentTraffic[link.index] += sent;
                                if (s === this.state.scenario) {
                                    linkUtilization[link.index] += weight * flow.demand * flow.permissable;
                                    // TODO 
                                    // linkUtilization[link.index] += sent;
                                }
                            });
                            if (s === this.state.scenario) {
                                tunnel.sent = sent;
                                satisfiedDemandForFlow += sent;
                            }
                            satisfiedDemandForScenario += sent;
                        }
                    })
                    if (s === this.state.scenario) {
                        flow.satisfied = satisfiedDemandForFlow;
                        flow.tunnels = flowTunnels;
                    }
                })
                scenarioSatisfaction.push(satisfiedDemandForScenario / totalDemand)
            });
        };
        this.setState({
            flows,
            scenarioSatisfaction,
            linkUtilization,
        }, () => {
            this.updateGraph();
            this.changeTunnel(0);
        });
    }

    // simulateScenario(s) {
    //     return flows, satifiedDemand, 
    // }

    dragstarted(d) {
      if (!d3.event.active) this.state.simulation.alphaTarget(0.3).restart();
      d.fx = d.x;
      d.fy = d.y;
    }

    dragged(d) {
      d.fx = d3.event.x;
      d.fy = d3.event.y;
    }

    dragended(d) {
      if (!d3.event.active) this.state.simulation.alphaTarget(0);
      d.fx = null;
      d.fy = null;
    }

    handleUtilization(opacity) {
        this.setState({
            showUtilization: opacity,
        }, this.updateGraph)
    }
    
    handleScenario(scenario) {
        let downLinks = [];
        this.simulateTraffic();
        this.state.scenarios[scenario].forEach((s, i) => {
            if (!s) {
                downLinks.push({src: String(this.state.links[i][0]), dst: String(this.state.links[i][1])});
            }
        });
        this.setState({
            downLinks: downLinks,
            scenario: scenario,
        }, () => {
            this.simulateTraffic();
        });
    }

    handleLimit(bool) {
        this.setState({
            limitTraffic: bool,
        }, () => {
            this.simulateTraffic();
        });
    }

    colorLinks(links, color){
        let forwardLinks = d3.selectAll('line').filter((d) => {
            let filter = false;
            links.forEach(link => {
                if (link.src === d.source.id && link.dst === d.target.id) { filter = true }
            })
            return filter;
        })
        let backLinks = d3.selectAll('line').filter((d) => {
            let filter = false;
            links.forEach(link => {
                if (link.dst === d.source.id && link.src === d.target.id) { filter = true }
            })
            return filter;
        })
        forwardLinks.style("stroke-opacity", .6);
        forwardLinks.style("stroke", color);
        backLinks.style("stroke-opacity", 0);
        backLinks.style("stroke", color);
    }

    colorNodes(nodes, color){
        let colorNodes = d3.selectAll('circle').filter(function(d) {return (nodes.includes(d.id))})
        colorNodes.style("fill", color);
    }

    dashLinks(links, dash, animate){
        // clearInterval(this.dashInterval);
        let forwardLinks = d3.selectAll('line').filter((d) => {
            let filter = false;
            links.forEach(link => {
                if (link.src === d.source.id && link.dst === d.target.id) { filter = true }
            })
            return filter;
        })
        let backLinks = d3.selectAll('line').filter((d) => {
            let filter = false;
            links.forEach(link => {
                if (link.dst === d.source.id && link.src === d.target.id) { filter = true }
            })
            return filter;
        })
        forwardLinks.style("stroke-opacity", 1);
        forwardLinks.style("stroke-dasharray", dash);
        // var offset = 1;
        // if (animate) {
        //     this.dashInterval = setInterval(function() {
        //         forwardLinks.style('stroke-dashoffset', offset);
        //         offset -= 1; 
        //     }, 50);
        // }
        // backLinks.style("stroke-opacity", 0);
        // backLinks.style("stroke-dasharray", dash);
        forwardLinks.attr('marker-end','url(#arrowhead)')
    }

    animateLinks(links){
        clearInterval(this.dashInterval);
        let forwardLinks = d3.selectAll('line').filter((d) => {
            let filter = false;
            links.forEach(link => {
                if (link.src === d.source.id && link.dst === d.target.id) { filter = true }
            })
            return filter;
        })
        let backLinks = d3.selectAll('line').filter((d) => {
            let filter = false;
            links.forEach(link => {
                if (link.dst === d.source.id && link.src === d.target.id) { filter = true }
            })
            return filter;
        })
        forwardLinks.style("stroke-opacity", 1);
        var offset = 1;
        this.dashInterval = setInterval(function() {
            forwardLinks.style('stroke-dashoffset', offset);
            offset -= 1; 
        }, 50);
        backLinks.style("stroke-opacity", 0);
        forwardLinks.attr('marker-end','url(#arrowhead)')
    }

    getTunnelNodes(tunnel) {
        let nodes = []
        tunnel.links.forEach(link => {
            if (!nodes.includes(link.src)) { nodes.push(link.src) };
            if (!nodes.includes(link.dst)) { nodes.push(link.dst) };
        })
        return nodes;
    }


    getFlow(node1, node2) {
        let ret = null
        Object.values(this.state.flows).forEach(flow => {
            if (flow.src === node1 && flow.dst === node2) {
                ret = flow
            }
        });
        return ret
    }

    getTunnels(f, node1, node2, s) {
        let allTunnels = []
        let tunnels = this.state.Tf[f];
        let total_weight = 0;
        let numAvailable = 0;
        tunnels.forEach((tunnel, t) => {
            total_weight += this.state.X[s][tunnel - 1] === 1 ? this.state.allocation[f][t] : 0;
            numAvailable += this.state.X[s][tunnel - 1] === 1 ? 1 : 0;
        });

        tunnels.forEach((tunnel, t) => {
            let availability = 0;
            this.state.probabilities.forEach((prob, s) => {
                availability += prob * this.state.X[s][tunnel - 1];
            })
            let weight = 0
            if (this.state.X[s][tunnel - 1] === 1) {
                weight = total_weight !== 0 ?
                        (this.state.allocation[f][t] / total_weight)  :
                        (1 / numAvailable);
            } else {
                weight = 0;
            }
            let edges_used = this.state.T[tunnel - 1]
            let links = [];
            edges_used.forEach(edge => {
                links.push({
                    "src": this.state.links[edge-1][0].toString(),
                    "dst": this.state.links[edge-1][1].toString(),
                    "index": edge - 1,
                });
            });
            if (weight > 0) {
                allTunnels.push({
                    links,
                    "allocation": this.state.allocation[f][t],
                    "weight": weight,
                    "availability": Math.round(availability * 1000000) / 1000000,
                    "id": (tunnel - 1),
                })
            }
        })
        return allTunnels
    }

    getBackLink(link) {
        let backindex = -1;
        this.state.links.forEach((l, i) => {
            if (l[0] === link[1] && l[1] === link[0]) { backindex = i }
        });
        return backindex != -1 ? {src: String(this.state.links[backindex][0]), dst: String(this.state.links[backindex][1])} : {};
    }

    addTip(id, line1, line2) {
        let circle = d3.selectAll("circle").filter(function (c, i) { return (c.id === id);});
        let g = circle.select(function() { return this.parentNode; })
        let tip = g.append("g")
          .attr("class", "tip")
          .attr("transform", "translate(" + 6  + "," + 6 + ")");

        var rect = tip.append("rect")
          .style("fill", "white")
          .style("stroke", "steelblue")
          .style("opacity", .8)

        tip.append("text")
          .text(line1)
          .attr("dy", "1.2em")
          .attr("x", 8);

        tip.append("text")
          .text(line2)
          .attr("dy", "2.4em")
          .attr("x", 8);

        let bbox = tip.node().getBBox();
        rect.attr("width", bbox.width + 15)
            .attr("height", bbox.height + 10)
    }

    updateGraph() {
        d3.selectAll('.tip').remove();
        d3.selectAll('line').each(function(d) {d3.select(this).style("stroke-opacity", .1)});
        d3.selectAll('line').each(function(d) {d3.select(this).style("stroke-dasharray", "")});
        d3.selectAll('line').each(function(d) {d3.select(this).style("stroke", "#888")});
        d3.selectAll('line').attr('marker-end','');
        d3.selectAll('circle').each(function(d) {d3.select(this).style("fill", "lightgrey")});
        
        this.state.secondaryTunnels.forEach((tunnel, i) => {
            this.dashLinks(tunnel, "5,5", false);
            this.colorLinks(tunnel, colors[i]);
        })
        // this.dashLinks(this.state.dashLinks, "5,5", true);
        this.animateLinks(this.state.dashLinks);
        this.colorNodes(this.state.secondaryNodes, "#bbb");
        this.colorNodes(this.state.colorNodes, "#aaa");

        d3.selectAll("circle").filter((c, i) => (c.id === this.state.firstSelected || c.id === this.state.secondSelected)).style("fill", "steelblue");
        this.state.tips.forEach(tip => {
            this.addTip(tip.id, tip.line1, tip.line2);
        })

        if (this.state.firstSelected === null) {
            this.resetColors();
        }
        this.colorLinks(this.state.downLinks, "red");
        this.showUtilization(this.state.showUtilization);
    }

    resetColors() {
        d3.selectAll('line').each(function(d) {d3.select(this).style("stroke-opacity", 1)});
        d3.selectAll('line').each(function(d) {d3.select(this).style("stroke-dasharray", "")});
        d3.selectAll('line').each(function(d) {d3.select(this).style("stroke", "#888")});
        d3.selectAll('line').attr('marker-end','');
        d3.selectAll('circle').each(function(d) {d3.select(this).style("fill", "black")});
    }

    clearGraph() {
        d3.selectAll("svg > .tip").remove();
        d3.selectAll("svg > .links").remove();
        d3.selectAll("svg > .nodes").remove();
        this.setState({
            showPaths: false,
            firstSelected: null,
            secondSelected: null,
            numSelected: 0,
            tips: [],
        }, () => {console.log(this.state)})
    }

    arrowPress(e) {
        // this.showUtilization();
        if (e.keyCode === 39 && this.state.flows[this.state.flowid]) {
            let tunnelIndex = (this.state.tunnelIndex + 1 >= this.state.flows[this.state.flowid].tunnels.length) ? 0 : this.state.tunnelIndex + 1;
            this.changeTunnel(tunnelIndex);
        } else if (e.keyCode === 37 && this.state.flows[this.state.flowid]) {
            let tunnelIndex = (this.state.tunnelIndex - 1 < 0) ? this.state.flows[this.state.flowid].tunnels.length - 1 : this.state.tunnelIndex - 1;
            this.changeTunnel(tunnelIndex);
        } else if (e.keyCode === 38 && this.state.scenarios.length > 0) {
            e.preventDefault();
            this.handleScenario(this.state.scenario - 1 < 0 ? this.state.scenarios.length - 1 : this.state.scenario - 1);
        } else if (e.keyCode === 40 && this.state.scenarios.length > 0) {
            e.preventDefault();
            this.handleScenario(this.state.scenario + 1 < this.state.scenarios.length ? this.state.scenario + 1 : 0);
        };

    }

    showUtilization(opacity) {
        let linkTraffic = this.state.linkUtilization;
        for (let i = 0; i <= linkTraffic.length - 1; i++) {
            let linklabel = d3.selectAll(".aEnd").filter(function (c, j) { return (j === i)});
            linklabel.html(`${Math.round((linkTraffic[i] / this.state.capacity[i]) * 100) / 1}%`);
            if (linkTraffic[i] / this.state.capacity[i] > 1) {
                linklabel.style("fill", "red")
            } else {
                linklabel.style("fill", "black")
            }
        }
        d3.selectAll(".aEnd").style("opacity", opacity);
    }

    changeTunnel(tunnelIndex) {
        let flowid = this.state.flowid;
        let flow = this.state.flows[flowid];
        let sent = flowid !== null ? (flow.tunnels[tunnelIndex].sent) : 0;
        let tunnels = flowid !== null ? flow.tunnels : [];
        let dashLinks = flowid !== null ? tunnels[tunnelIndex].links : [];
        let colorNodes = flowid !== null ? this.getTunnelNodes(tunnels[tunnelIndex]) : [];
        let secondaryNodes = []
        let secondaryTunnels = []
        if (flowid !== null) {
            flow.tunnels.forEach(tunnel => {
                secondaryNodes = [...secondaryNodes, ...this.getTunnelNodes(tunnel)];
                secondaryTunnels = [...secondaryTunnels, tunnel.links];
            });
        };
        let backFlowid = this.state.backFlowid;
        let backFlow = this.state.flows[backFlowid]
        // let sentBack = backFlowid !== null ? (backFlow.tunnels[tunnelIndex].weight * backFlow.demand) : 0;
        let tips = []
        if (this.state.numSelected == 2) {
            if (this.state.firstSelected != null) {
                tips.push({
                    id: this.state.firstSelected,
                    line1: `Node: ${this.state.firstSelected}`,
                    line2: `Sent: ${sent}`
                });
            }
            if (this.state.secondSelected != null) {
                tips.push({
                    id: this.state.secondSelected,
                    line1: `Node: ${this.state.secondSelected}`,
                    line2: `Received: ${sent}`,
                });
            }
        } else if (this.state.numSelected == 1) {
            let [demandedTo, demandedFrom] = this.getNodeDemand(this.state.firstSelected);
            demandedTo = this.state.limitTraffic ? (1 - this.state.var) * demandedTo : demandedTo;
            demandedFrom = this.state.limitTraffic ? (1 - this.state.var) * demandedFrom : demandedFrom;
            tips.push({
                id: this.state.firstSelected,
                line1: `Sent: ${demandedFrom}`,
                line2: `Received ${demandedTo}`,
            })
        }
       
        this.setState({
            tunnelIndex,
            dashLinks,
            colorNodes,
            secondaryTunnels,
            secondaryNodes,
            tips,
        }, this.updateGraph);
    }

    getNodeDemand(id) {
        let demandedFrom = 0;
        let demandedTo = 0;
        Object.values(this.state.flows).forEach(flow => {
            if (id === flow.src) { demandedFrom += this.state.demand[flow.id] }
            if (id === flow.dst) { demandedTo += this.state.demand[flow.id] }
        });
        return [demandedTo, demandedFrom]
    }


    click(d) {
      if (this.state.numSelected === 0 || this.state.numSelected === 2) {
        // document.removeEventListener("keydown", this.arrowPress, false);
        let [demandedTo, demandedFrom] = this.getNodeDemand(d.id);
        let permissable = this.state.limitTraffic ? 1 - this.state.var : 1;
        this.setState({
            numSelected: 1,
            firstSelected: d.id,
            secondSelected: null,
            showPaths: false,
            dashLinks: [],
            colorNodes: [],
            secondaryTunnels: [],
            secondaryTunnels: [],
            flowid: null,
            tips: [
                {
                    id: d.id,
                    line1: `Sent: ${demandedFrom * permissable}`,
                    line2: `Received ${demandedTo * permissable}`,
                }
            ],
        }, this.updateGraph);
      } else if (this.state.numSelected === 1) {
        if (this.state.firstSelected === d.id) {
            this.setState({
                numSelected: 0,
                firstSelected: null,
                secondSelected: null,
                tips: [],
                showPaths: false,
                colorNodes: [],
                dashLinks: [],
            }, this.updateGraph);
        } else {
            let flow = this.getFlow(this.state.firstSelected, d.id);
            let backFlow = this.getFlow(d.id, this.state.firstSelected);
            this.setState({
                numSelected: 2,
                secondSelected: d.id,
                showPaths: true,
                flowid: flow ? flow.id : null,
                backFlowid: backFlow ? backFlow.id : null,
            }, () => { this.changeTunnel(0) })
        }
      }
    }

    drawGraph(topology) {
        document.addEventListener("keydown", this.arrowPress, false);
        var simulation = d3.forceSimulation()
            .force("link", d3
                .forceLink().id(function(d) { return d.id; })
                .distance(function (d) {
                    return 100;
                })
            )
            .force("charge", d3.forceManyBody().strength(-500))
            .force("center", d3.forceCenter(this.svg.getBoundingClientRect().width / 2, this.svg.getBoundingClientRect().height / 2));


        this.setState({
            simulation: simulation,
        }, () => {
            const svg = d3.select(this.svg);
            svg.append('defs').append('marker')
                .attr('id', 'arrowhead')
                .attr('viewBox', '-0 -5 10 10')
                .attr('refX', 13)
                .attr('refY', 0)
                .attr('orient', 'auto')
                .attr('markerWidth', 3)
                .attr('markerHeight', 13)
                .attr('xoverflow', 'visible')
                .append('svg:path')
                .attr('d', 'M 0,-5 L 10 ,0 L 0,5')
                .attr('fill', '#999')
                .style('stroke','none');

            d3.json(`./data/${topology}.json`)
              .then((graph, error) => {
              if (error) throw error;
              this.setState({
                ...this.state,
                graph: graph,
              })

              graph.links.forEach((link, i) => {
                  link.capacity = this.state.capacity[i]
              })
              var linkg = svg.append("g")
                .attr("class", "links")
                .selectAll("line")
                .data(graph.links)
                .enter()
                .append("g")
                .attr("class", "link")


              var link = linkg
                .append("line")
                .attr("class", "link-line")

              var labelLine = svg.selectAll(".link")
                .append("text")
                .attr('class', 'aEnd')
                .data(graph.links)
                .attr('x', function(d) { return d.source.x; })
                .attr('y', function(d) { return d.source.y; })
                .attr('text-anchor', 'middle')
                .style("font-size", "10px")
                .style("opacity", 0)
                .text("yo");

              var div = d3.select("body").append("div")
                .attr("class", "tooltip")
                .style("opacity", 0);

            // var edgepaths = svg.selectAll(".edgepath")
            //     .data(graph.links)
            //     .enter()
            //     .append('path')
            //     .attrs({'d': function(d) {return 'M '+d.source.x+' '+d.source.y+' L '+ d.target.x +' '+d.target.y},
            //            'class':'edgepath',
            //            'fill-opacity':0,
            //            'stroke-opacity':0,
            //            'fill':'blue',
            //            'stroke':'red',
            //            'id':function(d,i) {return 'edgepath'+i}})
            //     .style("pointer-events", "none");

            // var edgelabels = svg.selectAll(".edgelabel")
            //     .data(graph.links)
            //     .enter()
            //     .append('text')
            //     .style("pointer-events", "none")
            //     .attrs({'class':'edgelabel',
            //            'id':function(d,i){return 'edgelabel'+i},
            //            'dx':80,
            //            'dy':0,
            //            'font-size':10,
            //            'fill':'#aaa'});

            // edgelabels.append('textPath')
            //     .attr('xlink:href',function(d,i) {return '#edgepath'+i})
            //     .style("pointer-events", "none")
            //     .text(function(d,i){return 'label '+i});

              var node = svg.append("g")
                .attr("class", "nodes")
                .selectAll("circle")
                .data(graph.nodes)
                .enter()
                .append('g').attr("class", "wrapper")
                  .attr("width", 10)
                  .attr("height", 10)
                  .on("click", this.click)
                  .call(d3.drag()
                      .on("start", this.dragstarted)
                      .on("drag", this.dragged)
                      .on("end", this.dragended));

              var circle = node.append("circle")
                  .attr("r", 14)

              node.append("text")
                .text(function (d) { return d.id; })
                .style("text-anchor", "middle")
                .style("fill", "#999")
                .style("cursor", "pointer")
                .style("font-size", 18)
                .attr("transform", function(d) {
                  return "translate(" + 0 + "," + 6+ ")"
                });

              node.append("title")
                  .text(function(d) { return d.id; });

              //add tooltip
              let that = this;
              svg.selectAll("line")
                  .on("mouseover", function(d) {
                      div.transition()
                          .duration(200)
                          .style("opacity", .9);
                      div.html("<i>p</i> = " + Math.round(that.state.failure_probabilities[d.index]*10000000)/100000 + "&#37;") //+ "<br/>"  + d.close
                          .style("width", "90px")
                          .style("left", (d3.event.pageX) + "px")
                          .style("top", (d3.event.pageY - 28) + "px");
                      })
                  .on("mouseout", function(d) {
                      div.transition()
                          .duration(200)
                          .style("opacity", 0);
                      });

              this.state.simulation
                  .nodes(graph.nodes)
                  .on("tick", ticked)

              this.state.simulation.force("link")
                  .links(graph.links);

              function xpos(s, t) {
                  var angle = Math.atan2(t.y - s.y, t.x - s.x);
                  return 30 * Math.cos(angle) + s.x;
              };

              function ypos(s, t) {
                  var angle = Math.atan2(t.y - s.y, t.x - s.x);
                  return 30 * Math.sin(angle) + s.y;
              };


              function ticked() {
                link
                    .attr("x1", function(d) { return d.source.x; })
                    .attr("y1", function(d) { return d.source.y; })
                    .attr("x2", function(d) { return d.target.x; })
                    .attr("y2", function(d) { return d.target.y; });

                svg.selectAll('text.aEnd')
                    .attr('x', function(d) { return xpos(d.source, d.target); })
                    .attr('y', function(d) { return ypos(d.source, d.target); });

                svg.selectAll('text.zEnd')
                    .attr('x', function(d) { return xpos(d.target, d.source); })
                    .attr('y', function(d) { return ypos(d.target, d.source); });

                // labelLine.attr('transform',function(d,i){
                //     if (d.target.x<d.source.x){
                //         let bbox = this.getBBox();
                //         let rx = bbox.x+bbox.width/2;
                //         let ry = bbox.y+bbox.height/2;
                //         return 'rotate(180 '+ rx+' '+ ry+')';
                //         }
                //     else {
                //         return 'rotate(0)';
                //         }
                // });

                // edgepaths.attr('d', function(d) { var path='M '+d.source.x+' '+d.source.y+' L '+ d.target.x +' '+d.target.y;
                //                                    //console.log(d)
                //                                    return path});

                // edgelabels.attr('transform',function(d,i){
                //     if (d.target.x<d.source.x){
                //         let bbox = this.getBBox();
                //         let rx = bbox.x+bbox.width/2;
                //         let ry = bbox.y+bbox.height/2;
                //         return 'rotate(180 '+rx+' '+ry+')';
                //         }
                //     else {
                //         return 'rotate(0)';
                //         }
                // });

                node.attr("transform", function(d) {
                  return "translate(" + d.x + "," + d.y + ")"
                });
              }
            });
        })
    }

  render() {
    // let links = [];
    // if (this.state.graph) {
    //     links = this.state.graph.links.map(link => {
    //         return <line className="link" x="100" y="100"/>
    //     })
    //     console.log(d3.select("line"))
    // }
    let path_info;
    if (this.state.flowid != null) {
        path_info = this.state.flows[this.state.flowid].tunnels.map((tunnel, i) => {
            return tunnel.weight > 0 ? <tr
                        className={i === this.state.tunnelIndex ? "selected" : ""}
                        onClick={() => this.changeTunnel(i)}
                        key={i}
                    >
                        <td x="0">Tunnel {i}</td>
                        <td x="50">{tunnel.weight}</td>
                        <td x="80">{tunnel.availability}</td>
                    </tr> : <tr></tr>
        });
    }

    let limitButton = this.state.limitTraffic ?
                            <div id="limitButton" onClick={() => this.handleLimit(false)}>Unlimit</div> :
                            <div id="limitButton" onClick={() => this.handleLimit(true)}>Limit</div>

    let utilizationButton = this.state.showUtilization === 0 ?
                            <div id="utilizationButton" onClick={() => this.handleUtilization(.6)}>Utilization</div> :
                            <div id="utilizationButton" onClick={() => this.handleUtilization(0)}>Off</div>

    let key = 0;
    let demand = [];
    let sentDemand = [];
    let satisfied = [];
    let thead = [];
    let demandRows = [];
    let sentRows = [];
    let satisfiedRows = [];
    let totalSatisfied = 0;
    let totalDemand = 0;

    for (let i = 1; i <= parseInt(this.state.num_nodes); i++) {
        thead.push(<th className="border-bottom" key={key++}>{i}</th>)
        let demandRow = [];
        let sentRow = [];
        let satisfiedRow = [];
        for (let j = 1; j <= parseInt(this.state.num_nodes); j++) {
            let d = "-"
            let sentDemand = 0
            let satisfiedDemand = 0
            Object.values(this.state.flows).forEach((flow, f) => {
                if (flow.src === i.toString() && flow.dst === j.toString()) {
                    satisfiedDemand = flow.satisfied;
                    d = flow.demand;
                }
            })
            demandRow.push(<td>{d === "-" ? d : Math.round(d * 10000)/10000}</td>)
            sentRow.push(<td>{satisfiedDemand === 0 ? "-" : Math.round(satisfiedDemand * 100000)/100000}</td>)
            satisfiedRow.push(<td>{d === "-" ? "-" : `${Math.round((satisfiedDemand * 10000)/ d) / 100}%`}</td>)
            totalSatisfied += satisfiedDemand;
            totalDemand += d === "-" ? 0 : d;
        }
        demandRows.push(<tr key={key++}><th className="border-right">{i}</th>{demandRow}</tr>)
        sentRows.push(<tr key={key++}><th className="border-right">{i}</th>{sentRow}</tr>)
        satisfiedRows.push(<tr key={key++}><th className="border-right">{i}</th>{satisfiedRow}</tr>)

    }
    demand.push(<tr key={key++}><th></th>{thead}</tr>)
    demand.push(demandRows)
    sentDemand.push(<tr key={key++}><th></th>{thead}</tr>)
    sentDemand.push(sentRows)
    satisfied.push(<tr key={key++}><th></th>{thead}</tr>)
    satisfied.push(satisfiedRows)

    // let scenarios;
    // if (this.state.scenarios && this.state.scenarioSatisfaction) {
    //     scenarios = this.state.scenarios.map((scenario, i) => {
    //         return (<option
    //                 key={i}
    //                 value={i}>{`Scenario ${i} (${Math.round(this.state.probabilities[i] * 1000000) / 10000}%)
    //                             (${Math.round((this.state.scenarioSatisfaction[i]) * 1000000) / 10000})`}
    //                 </option>)
    //     })
    // }


    let scenarios;
    if (this.state.scenarios && this.state.scenarioSatisfaction) {
        scenarios = this.state.scenarios.map((scenario, i) => {
            return <tr
                        className={i === this.state.scenario ? "selected" : ""}
                        onClick={() => this.handleScenario(i)}
                        key={i}
                    >
                        <td x="0">Scenario {i}</td>
                        <td x="50">{Math.round(this.state.probabilities[i] * 1000000) / 10000}%</td>
                        <td x="80">{Math.round((this.state.scenarioSatisfaction[i]) * 1000000) / 10000}%</td>
                    </tr>
        });
    }

    let cvar;
    if (this.state.cvar) {
        cvar = (<tbody>
                    <tr>
                        <th className="border-bottom" style={{"paddingLeft": "10px"}}>VAR</th>
                        <th className="border-bottom">CVAR</th>
                    </tr>
                    <tr>
                        <td style={{"paddingLeft": "20px"}}>{this.state.var}</td>
                        <td>{`${Math.round(this.state.cvar * 1000000) / 10000}%`}</td>
                    </tr>
                </tbody>)
    }

    return (
      <StyledResults>
          <SVG
            ref={svg => this.svg = svg}
          >
            {/**<g className="l">
                { links }
            </g>**/}
            <foreignObject x="0" y="0" width="100%" height="100%" pointerEvents="none">
                { limitButton }
            </foreignObject>
            <foreignObject x="0" y="0" width="100%" height="100%" pointerEvents="none">
                { utilizationButton }
            </foreignObject>
            {/* <foreignObject x="0" y="0" width="100%" height="100%" pointerEvents="none">
                <select onChange={e => this.handleScenario(e.target.value)} value={this.state.scenario}>
                    { scenarios }
                </select>
            </foreignObject> */}
            
            <foreignObject x="0" y="0" width="100%" height="100%" pointerEvents="none" style={{"padding": "14px"}}>
            {this.state.scenarios && this.state.scenarioSatisfaction &&
                <ScenarioTable>
                <div className="table-scroll">
                    <tbody>
                        <tr>
                            <th></th>
                            <th>availability</th>
                            <th>demand satisfied</th>
                        </tr>
                        { scenarios }
                    </tbody>
                </div>
                </ScenarioTable>
            }
            </foreignObject>
            {this.state.showPaths &&
                <foreignObject x="0" y="0" width="100%" height="100%" pointerEvents="none" style={{"padding": "14px"}}>
                  <PathTable>
                    <tbody>
                        <tr>
                            <th></th>
                            <th>weight</th>
                            <th>availability</th>
                        </tr>
                        { path_info }
                    </tbody>
                  </PathTable>
                </foreignObject>
            }
          </SVG>
          <div className="tableTitle">Demand</div>
          <OuterTable>
            <tbody>
                { demand }
            </tbody>
          </OuterTable>
          <div className="tableTitle">Successful Demand</div>
          <OuterTable>
            <tbody>
                { sentDemand }
            </tbody>
          </OuterTable>
          <div className="tableTitle">Satisfied Demand</div>
          <OuterTable>
            <tbody>
                { satisfied }
            </tbody>
          </OuterTable>
          <div className="tableTitle">Loss</div>
          <OuterTable>
                { cvar }
          </OuterTable>
      </StyledResults>

    )
  }
}

export default ForceGraph;
