import React, { Component } from 'react';
import styled from 'styled-components';

const Allocation = styled.div`
  color: white;
`;

const Table = styled.table`
  color: white;
  background-color: #444;
  border-radius: 10px;
  margin: 30px auto;
  tr {
    border: 1px solid gray;
    td {
      padding: 10px;
    }
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


class TEOutputs extends Component {

    constructor(props) {
        super(props);
        // let flows = new Array(6);
        // let demand = new Array(6);
        // let satisfied = new Array(6);
        // for (let i = 0; i < flows.length; i++) {
        //   demand[i] = new Array(6);
        //   flows[i] = new Array(6);
        //   satisfied[i] = new Array(6);
        //   for (let j = 0; j < 6; j++) {
        //     flows[i][j] = "-";
        //     demand[i][j] = "-";
        //     satisfied[i][j] = "-";
        //   }
        // }


        // this.state = {
        //   flows: flows,
        //   demand: demand,
        //   satisfied: satisfied,
        // }
      let flows = new Array(Number(props.num_nodes));
      let demand = new Array(Number(props.num_nodes));
      let satisfied = new Array(Number(props.num_nodes));
      for (let i = 0; i < flows.length; i++) {
        flows[i] = new Array(Number(props.num_nodes));
        demand[i] = new Array(Number(props.num_nodes));
        satisfied[i] = new Array(Number(props.num_nodes));
        for (let j = 0; j < props.num_nodes; j++) {
          flows[i][j] = "-";
          demand[i][j] = "-";
          satisfied[i][j] = "-";
        }
      }
      let offset = props.zeroindex ? 1 : 0;
      for (let i = 0; i < props.data.flows.length; i++) {
        let a = props.data.allocation[i].reduce((partial_sum, s) => partial_sum + s);
        flows[props.data.flows[i][0]-offset][props.data.flows[i][1]-offset] = Math.round(a * 100) / 100;
        demand[props.data.flows[i][0]-offset][props.data.flows[i][1]-offset] = Math.round(props.data.demand[i] * 100) / 100;
        satisfied[props.data.flows[i][0]-offset][props.data.flows[i][1]-offset] = Math.round(a /props.data.demand[i] * 100) + "%";
      };
      this.state = {
        ...this.state,
        flows: flows,
        demand: demand,
        satisfied: satisfied,
      }
    }

    componentWillReceiveProps(props) {
      console.log(props)
      let flows = new Array(Number(props.num_nodes));
      let demand = new Array(Number(props.num_nodes));
      let satisfied = new Array(Number(props.num_nodes));
      for (let i = 0; i < flows.length; i++) {
        flows[i] = new Array(Number(props.num_nodes));
        demand[i] = new Array(Number(props.num_nodes));
        satisfied[i] = new Array(Number(props.num_nodes));
        for (let j = 0; j < props.num_nodes; j++) {
          flows[i][j] = "-";
          demand[i][j] = "-";
          satisfied[i][j] = "-";
        }
      }
      let offset = props.zeroindex ? 1 : 0;
      for (let i = 0; i < props.data.flows.length; i++) {
        let a = props.data.allocation[i].reduce((partial_sum, s) => partial_sum + s);
        flows[props.data.flows[i][0]-offset][props.data.flows[i][1]-offset] = Math.round(a * 100) / 100;
        demand[props.data.flows[i][0]-offset][props.data.flows[i][1]-offset] = Math.round(props.data.demand[i] * 100) / 100;
        satisfied[props.data.flows[i][0]-offset][props.data.flows[i][1]-offset] = Math.round(a /props.data.demand[i] * 100) + "%";
      };
      this.setState({
        ...this.state,
        flows: flows,
        demand: demand,
        satisfied: satisfied,
      })
    }

    render() {
        let key = 0;
        let flows = []
        let thead = []
        if (this.state.flows[0]) {
          for (let i = 0; i < this.state.flows[0].length; i++) {
            thead.push(<th className="border-bottom" key={key++}>{i}</th>)
          }
        }
        flows.push(<tr key={key++}><th></th>{thead}</tr>)

        for (let i = 0; i < this.state.flows.length; i++) {
          let row = this.state.flows[i]
          let rowDOM = []
          for (let j = 0; j < row.length; j++) {
            rowDOM.push(<td key={key++}>{row[j]}</td>);
          }
          flows.push(<tr key={key++}><th className="border-right">{i}</th>{rowDOM}</tr>);
        }


        let demand = []
        thead = []
        if (this.state.demand[0]) {
          for (let i = 0; i < this.state.demand[0].length; i++) {
            thead.push(<th className="border-bottom" key={key++}>{i}</th>)
          }
        }
        demand.push(<tr key={key++}><th></th>{thead}</tr>)

        for (let i = 0; i < this.state.demand.length; i++) {
          let row = this.state.demand[i]
          let rowDOM = []
          for (let j = 0; j < row.length; j++) {
            rowDOM.push(<td key={key++}>{row[j]}</td>);
          }
          demand.push(<tr key={key++}><th className="border-right">{i}</th>{rowDOM}</tr>);
        }

        let satisfied = []
        thead = []
        if (this.state.satisfied[0]) {
          for (let i = 0; i < this.state.satisfied[0].length; i++) {
            thead.push(<th className="border-bottom" key={key++}>{i}</th>)
          }
        }
        satisfied.push(<tr key={key++}><th></th>{thead}</tr>)

        for (let i = 0; i < this.state.satisfied.length; i++) {
          let row = this.state.satisfied[i]
          let rowDOM = []
          for (let j = 0; j < row.length; j++) {
            rowDOM.push(<td key={key++}>{row[j]}</td>);
          }
          satisfied.push(<tr key={key++}><th className="border-right">{i}</th>{rowDOM}</tr>);
        }
        return (
          <div>
            <Table>
              <tbody>
                {flows}
              </tbody>
            </Table>
            <Table>
              <tbody>
                {demand}
              </tbody>
            </Table>
            <Table>
              <tbody>
                {satisfied}
              </tbody>
            </Table>
          </div>
        );
    }
}

export default TEOutputs;
