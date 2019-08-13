import React, { Component } from 'react';
import styled from 'styled-components';
import * as d3 from "d3";

const StyledOutputs = styled.div`
    position: relative;
    svg {
        font-family: Sans-Serif, Arial;
    }
    .line {
      stroke-width: 4;
      fill: none;
    }

    .axis path {
      stroke: black;
    }

    .text {
      font-size: 12px;
    }

    .title-text {
      font-size: 12px;
    }

    #all-statements {
      display: block;
      width: 100%;
      border-bottom: 1px solid black;
    }

    #statement-table {
      background-color: #EEE;
      margin-top: 10px;
    }

    #statements {
      width: 40%;
      margin: 0px auto;
      margin-bottom: 70px;
      background-color: #EEE;
      padding: 20px;
      border-radius: 5px;
      font-size: 18px;
      text-align:center;

      div {
        margin: 20px 0px;
      }
      .colorGreen {
        color: rgb(0,150,0);
      }
      .colorRed {
        color: rgb(150, 0,0);
      }
    }
`;

const SVG = styled.svg`
  display: block;
  margin: -60px auto 0px auto;
  height: 700px;
  width: 900px;
`;

const AllocationTable = styled.table`
    border: 1px solid gray;
    background-color: rgba(255, 255, 255, .2);
    margin: 0px auto;
    th {
        padding: 3px 10px;
    }

    td {
        padding: 5px 10px;
        text-align: center;
    }

    .selected {
        background-color: rgba(200, 200, 200, .6);
    }
`;

const InfoTable = styled.table`
    border: 1px solid gray;
    background-color: rgba(255, 255, 255, .2);
    margin: 10px auto;
    margin-top: 70px;

    th {
        padding: 3px 10px;
    }

    td {
        padding: 5px 10px;
        text-align: center;
    }

    .selected {
        background-color: rgba(200, 200, 200, .6);
    }
`;

class StockOutputs extends Component {
    constructor(props){
        super(props)
        console.log(props)
        this.state = {
            beta: props.data.optimal_b,
            roi: props.roi/props.budget,
            cvar: props.data.optimal_cvar,
            var: props.data.optimal_var,
            a: props.data.optimal_a,
            budget: props.budget,
            selected: {
              allocation: props.data.optimal_a,
              var: props.data.optimal_var,
              cvar: props.data.optimal_cvar,
              gain: props.roi/props.budget,
              name: "test_" + props.data.optimal_b,
              id: -1,
            }
        }
        this.drawGraph = this.drawGraph.bind(this);
        this.selectLine = this.selectLine.bind(this);
        this.highlightCircles = this.highlightCircles.bind(this);
    }

    componentDidMount() {
        this.drawGraph(this.props.data)
    }

    componentWillReceiveProps(props) {
        console.log(props);
        this.setState({
          // allocation: props.data.optimal_a,
          // var: props.data.optimal_var,
          // cvar: props.data.optimal_cvar,
          beta: props.data.optimal_b,
          roi: props.roi/props.budget,
          cvar:  props.data.optimal_cvar,
          var: props.data.optimal_var,
          budget: props.budget,
          a: props.data.optimal_a,
          selected: {
            allocation: props.data.optimal_a,
            var: props.data.optimal_var,
            cvar: props.data.optimal_cvar,
            gain: props.roi/props.budget,
            name: "test_" + props.data.optimal_b,
          }
        })
        this.drawGraph(props.data);
    }

    selectLine(d) {
        console.log(d)
        this.setState({
            selected: d,
        }, () => {
          this.highlightCircles();
        })
    }

    highlightCircles() {
        d3.selectAll("circle").style("opacity", .5)
        d3.selectAll("circle").attr("r", 6)
        if (this.state.selected) {
          let circle = d3.selectAll("circle").filter((c, i) => (c.id === this.state.selected.id));
          circle.style("opacity", 1);
          circle.attr("r", 8)
        }

    }

    drawGraph(d) {
    console.log(d)
    var beta_vals = d.beta
    var g_vals = d.gains
    var id = 0;
    var data = beta_vals.map((b,i) => {
      var values = g_vals.map((g,j) => {
        return {
          gain: g,
          cvar: d.cvar[i][j],
          var: d.var[i][j],
          allocation: d.allocation[i][j],
          name: "test_" + b,
          line_id: i,
          point_id: j,
          id: id++,
        }
      });
      return {
        name: "Beta=" + b,
        values: values,
        beta: b,
        id: i,
      }
    });
    var line_id = data.length
    data.push({
      name: "Beta=" + d.optimal_b,
      beta: d.optimal_b,
      id: id++,
      values: [{
          gain: this.props.roi/this.props.budget,
          cvar: d.optimal_cvar,
          var: d.optimal_var,
          allocation: d.optimal_a,
          name: "test_" + d.optimal_b,
          line_id: line_id + 1,
          point_id: -1,
          id: -1,
      }],
    })

    console.log(data)
    var width = 800;
    var height = 600;
    var margin = 100;
    var duration = 100;

    var lineOpacity = "0.25";
    var lineOpacityHover = "0.6";
    var otherLinesOpacityHover = "0.1";
    var lineStroke = "4px";
    var lineStrokeHover = "4px";

    var circleOpacity = '0.85';
    var circleOpacityOnLineHover = "0.25"
    var circleRadius = 6;
    var circleRadiusHover = 8;

    /* Scale */
    var xScale = d3.scaleLinear ()
      .domain(d3.extent(data[0].values, d => d.gain))
      .range([0, width-margin]);

    var scalesY = d.cvar
    scalesY.push([d.optimal_cvar])
    var yScale = d3.scaleLinear()
      .domain([d3.min(scalesY.map(cvar => d3.min(cvar, d => d)), d => d), d3.max(scalesY.map(cvar => d3.max(cvar, d => d)), d => d)])
      .range([height-margin, 0]);

    var color = d3.scaleOrdinal(d3.schemeCategory10);

    /* Add SVG */
    var svg = d3.select(this.svg)
      .append('g')
      .attr("height", (height + margin) + "px")
      .attr("width", (width + margin) + "px")
      .attr("transform", `translate(${margin}, ${margin})`);

    svg.append("text")
      .attr("class", "title-text")
      .attr("text-anchor", "middle")
      .attr("x", (width-margin)/2)
      .attr("y", 5);

    /* Add line into SVG */
    var line = d3.line()
      .x(d => xScale(d.gain))
      .y(d => yScale(d.cvar));

    let lines = svg.append('g')
      .attr('class', 'lines');


    let highlightCircles = this.highlightCircles;
    lines.selectAll('.line-group')
      .data(data).enter()
      .append('g')
      .attr('class', 'line-group')
      .append('path')
      .attr('class', 'line')
      .attr('d', d => line(d.values))
      .style('stroke', (d, i) => color(i))
      .style('opacity', lineOpacity)
      .on("mouseover", function(d, i) {
          d3.selectAll('.line')
            .style('opacity', otherLinesOpacityHover);
          d3.selectAll("circle").filter((c, i) => (c.line_id === d.id))
            .attr('opacity', 1);
          d3.select(this)
            .style('opacity', lineOpacityHover)
            .style("stroke-width", lineStrokeHover)
            .style("cursor", "pointer");
        })
      .on("mouseout", function(d) {
          highlightCircles();
          d3.select(this)
            .style('opacity', lineOpacity)
            .style("stroke-width", lineStroke)
            .style("cursor", "pointer");
        });


    /* Add circles in the line */
    lines.selectAll("circle-group")
      .data(data).enter()
      .append("g")
      .attr("id", (d,i) => `circle-group-${i}`)
      .attr("class", "circle-group")
      .style("fill", (d, i) => color(i))
      .selectAll("circle")
      .data(d => d.values).enter()
      .append("g")
      .attr("class", "circle")
      .attr("id", (d,i) => `circle-${i}`)
      .on("click", this.selectLine)
      // .on("mouseover", function(d) {
      //     d3.select(this)
      //       .style("cursor", "pointer")
      //       .append("text")
      //       .attr("class", "text")
      //       .text(`${d.cvar}`)
      //       .attr("x", d => xScale(d.gain) + 5)
      //       .attr("y", d => yScale(d.cvar) - 10);
      //   })
      // .on("mouseout", function(d) {
      //     d3.select(this)
      //       .style("cursor", "none")
      //       .transition()
      //       .duration(duration)
      //       .selectAll(".text").remove();
      //   })
      .append("circle")
      .attr("cx", d => xScale(d.gain))
      .attr("cy", d => yScale(d.cvar))
      .attr("r", circleRadius)
      .style('opacity', circleOpacity)
      .on("mouseover", function(d, i) {
          d3.selectAll("circle").filter((c, i) => (c.id === d.id))
            .attr("r", circleRadiusHover);
        })
      .on("mouseout", function(d) {
          d3.selectAll("circle").filter((c, i) => (c.id === d.id))
            .attr("r", circleRadius);
          highlightCircles();
      })

    d3.selectAll(".circle-group")
      .append("text")
      .attr("class", "text")
      .text(d => d.name)
      .attr("x", d => xScale(d.values[0].gain) + 20)
      .attr("y", d => yScale(d.values[0].cvar))

    /* Add Axis into SVG */
    var formatter = d3.format(".3p");
    var xAxis = d3.axisBottom(xScale).ticks(5).tickFormat(formatter);
    var yAxis = d3.axisLeft(yScale).ticks(5).tickFormat(formatter);

    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", `translate(0, ${height-margin})`)
      .call(xAxis)
      .append('text')
        .attr("x", (width-margin)/2)
        .attr("y", "45")
        .attr("text-anchor", "middle")
        .attr("fill", "#000")
        .attr("font-size", "18px")
        .text("Return on Investment (%)");

    svg.append("g")
      .attr("class", "y axis")
      .attr("dy", "1em")
      .call(yAxis)
      .append('text')
      .attr("y", -50)
      .attr("x", -(height - margin)/2)
      .attr("text-anchor", "middle")
      .attr("transform", "rotate(-90)")
      .attr("fill", "#000")
      .attr("font-size", "18px")
      .text("Conditional Value at Risk (%)");

    this.highlightCircles();
  }
    render() {
        let allocation_info;
        let point_info;
        let statement_header = []
        let statement_weights = []
        this.state.a.forEach((w,i) => {
            statement_header.push(<th x="0">{this.props.tickers[i]}</th>)
            statement_weights.push(<td x="0">${Math.round(w * 100 * this.state.budget)/100}</td>)
        })

        if (this.state.selected) {
            point_info = (<tr>
                            <td x="0">{Math.round(this.state.selected.var * 100000)/1000}%</td>
                            <td x="50">{Math.round(this.state.selected.cvar * 100000)/1000}%</td>
                            <td x="50">{Math.round(this.state.selected.gain * 100000)/1000}%</td>
                        </tr>)
            allocation_info = this.state.selected.allocation.map((w, i) => {
                return <tr key={i}>
                            <td x="0">{this.props.tickers[i]}</td>
                            <td x="50">{Math.round(w * 100000)/1000}%</td>
                        </tr>
            })
        }

        console.log(this.state)
        return (
          <StyledOutputs>
            <div id="all-statements">
              <InfoTable id="statement-table">
                <tbody>
                  <tr>
                    {statement_header}
                  </tr>
                  <tr>
                    {statement_weights}
                  </tr>
                </tbody>
              </InfoTable>
              <div id="statements">
                <div>Your gain is
                  <span className="colorGreen"> {Math.round(this.state.roi * 100 * this.state.budget)/100}$ </span>
                  return on invesment
                </div>
                <div>Your loss is no less than
                  <span className="colorRed"> {Math.round(this.state.var * 100 * this.state.budget)/100}$ </span>
                  with probability
                  <span className="colorGreen"> {Math.round(this.state.beta * 100000)/1000}% </span>
                </div>
                <div>In the worst
                  <span className="colorGreen"> {Math.round((1-this.state.beta) * 100000)/1000}% </span>
                  of days, your average loss is
                  <span className="colorRed"> {Math.round(this.state.cvar * 100 * this.state.budget)/100}$</span>
                </div>
              </div>
            </div>
            <InfoTable>
              <tbody>
                  <tr>
                      <th>VAR</th>
                      <th>CVAR</th>
                      <th>ROI</th>
                  </tr>
                  { point_info }
              </tbody>
            </InfoTable>
            <AllocationTable>
              <tbody>
                  <tr>
                      <th>Ticker</th>
                      <th>weight</th>
                  </tr>
                  { allocation_info }
              </tbody>
            </AllocationTable>
            <SVG
              ref={svg => this.svg = svg}
            >
            </SVG>

 {/*<div>
               VAR:
               <div>
                 {this.props.data.var}
               </div>
             </div>
             <div>
               CVAR:
               <div>
                 {this.props.data.cvar}
               </div>
             </div>
             <div>
               Allocation:
               <div>
                 {this.props.data.allocation}
               </div>
             </div>*/}
          </StyledOutputs>
        );
    }
}

export default StockOutputs;
