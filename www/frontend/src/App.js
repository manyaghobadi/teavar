import React, { Component } from 'react';
import Header from './Header';
import TEInputs from './TEInputs';
import StockInputs from './StockInputs';
import TEOutputs from './TEOutputs';
import Login from './Login';
import StockOutputs from './StockOutputs';
import ForceGraph from './ForceGraph';

import styled from 'styled-components';
import './style.css';

const TESection = styled.div`
    width: 100vw;
    height: 70vh;

    #inputs {
        text-align: center;
        padding-top: 40px;
        width: 100%;
    }
    #graph {
        background-color: #EEE;
        margin-top: 20px;
        border: 1px solid gray;
        height: 80vh;
        width: 90%;
        margin-left: auto;
        margin-right: auto;
    }
`;

const StyledError = styled.div`
    background-color: #CCC
    padding: 20px;
    text-align: center;
    transition: .1s all;

    &:hover {
        background-color: #999;
        cursor: pointer;
    }
`;

class App extends Component {

    constructor(props) {
        super(props);
        this.state = {
            login: false,
            te: {
                inputs: {
                    topology: "Custom",
                    demand: "1",
                    path: "ED",
                    beta: ".9",
                    cutoff: ".0001",
                    k: "4",
                    downscale_demand: "1000",
                    zeroindex: "false",
                    demand_matrix: "true",
                    num_nodes: 0,
                },
                results: {
                    var: 0,
                    cvar: 0,
                    allocation: [],
                    flows: [],
                    capacity: [],
                    T: [],
                    Tf: [],
                    links: [],
                },
                show_results: false,
            },
            stocks: {
                inputs: {
                    tickers: [
                        ""
                    ],
                    beta: .9,
                    roi: 50,
                    target: 40,
                    days: 800,
                    budget: 1000,
                    KEYS: ["F6JGTHROSNY4A8MV", "EGZPCEQOXI85VKRT", "ASDPVYC2XRAJJ81K", "M4XW13HI1CWYH0KN"],
                    key: 0,
                },
                results: {

                },
                show_results: false,
            },
            error: "",
            mode: "TE",
        };
        this.setMode = this.setMode.bind(this);
        this.login = this.login.bind(this);
        this.removeError = this.removeError.bind(this);
        this.handleTESubmit = this.handleTESubmit.bind(this);
        this.handleTEInput = this.handleTEInput.bind(this);
        this.handleStockInput = this.handleStockInput.bind(this);
        this.handleTickerValue = this.handleTickerValue.bind(this);
        this.handleAddTicker = this.handleAddTicker.bind(this);
        this.handleTickerSubmit = this.handleTickerSubmit.bind(this);
    }

    setMode(mode) {
        this.setState({
            ...this.state,
            mode: mode,
        });
    }

    removeError() {
        this.setState({
            ...this.state,
            error: "",
        });
    }

    login(password) {
        if (password === "CVaR2019!") {
            this.setState({
                ...this.state,
                login: true,
            });       
        };
    }

    ////////////////////////////////////////////////////////////////////
    /////////////////////////// Stock Methods //////////////////////////
    ////////////////////////////////////////////////////////////////////
    handleStockInput(value, type) {
        this.setState({
            ...this.state,
            stocks: {
                ...this.state.stocks,
                inputs: {
                    ...this.state.stocks.inputs,
                    [type]: value,
                },
                show_results: false,
            }
        })
    }

    handleTickerValue(value, num) {
        let newtickers = this.state.stocks.inputs.tickers;
        newtickers[num] = value;
        this.setState({
            ...this.state,
            stocks: {
                inputs: {
                    ...this.state.stocks.inputs,
                    tickers: newtickers,
                },
                show_results: false,
            },
        })
        // fetch(`https://www.alphavantage.co/query?function=SYMBOL_SEARCH&keywords=${value}&apikey=${this.state.stocks.inputs.KEY}`, {
        //   method: "GET",
        //   mode: "cors"
        // }).then(res => {
        //     console.log(res);
        //     return res.json();
        // })
        // .then(data => {
        //     console.log(data.bestMatches);
        //     this.setState({
        //         stocks: {
        //             ...this.state.stocks,
        //             tickerMatches: data.bestMatches,
        //         }
        //     }, () => {
        //         console.log(this.state)
        //     })
        // })
        // .catch(err => console.log(err))


    }

    handleAddTicker() {
        let newtickers = this.state.stocks.inputs.tickers;
        newtickers.push("");
        this.setState({
            ...this.state,
            stocks: {
                ...this.state.stocks,
                inputs: {
                    ...this.state.stocks.inputs,
                    tickers: newtickers,
                },
                show_results: false,
            },
        })
    }

    handleTickerSubmit() {
        let returns = [];
        let ticker_ordered = [];
        console.log(this.state.stocks.inputs.key)
        Promise.all(
            this.state.stocks.inputs.tickers.map(ticker => {
                return new Promise((resolve, reject) => {
                    fetch(`https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=${ticker}&outputsize=full&apikey=${this.state.stocks.inputs.KEYS[this.state.stocks.inputs.key]}`, {
                      method: "GET",
                      mode: "cors"
                    }).then(res => res.json())
                    .then(data => {
                        let daily_returns = []
                        let daily_data = data["Time Series (Daily)"];
                        let close = "4. close";
                        let days = Object.keys(daily_data);
                        let last = daily_data[days[this.state.stocks.inputs.days + 1]][close]
                        for (let i = this.state.stocks.inputs.days; i >= 0; i--) {
                            let curr = daily_data[days[i]][close];
                            daily_returns.push((curr - last) / last);
                            last = curr;
                        }
                        returns.push(daily_returns);
                        ticker_ordered.push(ticker);
                        resolve();
                    })
                    .catch(error => {
                        reject(error);
                    });
                })
            })
        )
        .then(() => {
            console.log({
                "nstocks": this.state.stocks.inputs.tickers.length,
                "returns": returns,
                "beta": this.state.stocks.inputs.beta,
                "ticker_ordered": ticker_ordered,
              })
            // var url = 'http://localhost:8080/api/cvarf';
            var url = 'http://128.30.92.156:8080/api/cvarf';
            fetch(url, {
              method: "POST",
              mode: "cors",
              body: JSON.stringify({
                "nstocks": this.state.stocks.inputs.tickers.length,
                "returns": returns,
                "beta": parseFloat(this.state.stocks.inputs.beta),
                "roi": parseFloat(this.state.stocks.inputs.roi/this.state.stocks.inputs.budget),
                "target": parseFloat(this.state.stocks.inputs.target/this.state.stocks.inputs.budget),
              }),
              headers:{
                'Content-Type': 'application/json'
              }
            }).then(res => res.json())
            .then(response => {
                this.setState({
                    ...this.state,
                    stocks: {
                        ...this.state.stocks,
                        results: response,
                        show_results: true,
                        tickers: ticker_ordered,
                    },
                })
            })
            .catch(error => console.error('Error:', error));
        })
        .catch(error => {
            console.log(error);
            let oldkey = this.state.stocks.inputs.key;
            let newkey = this.state.stocks.inputs.key+1 >= this.state.stocks.inputs.KEYS.length ? 0 : this.state.stocks.inputs.key+1
            this.setState({
                ...this.state,
                stocks: {
                    ...this.state.stocks,
                    inputs: {
                        ...this.state.stocks.inputs,
                        key: newkey,
                    },
                },
                error: {
                    error: error,
                    message: `API error with key ${oldkey}...`,
                }
            })
        });
    }

    ////////////////////////////////////////////////////////////////////
    /////////////////////////// TE Methods /////////////////////////////
    ////////////////////////////////////////////////////////////////////
    handleTEInput(value, type) {
        console.log(this.state.te.inputs)
        this.setState({
            ...this.state,
            te: {
                ...this.state.te,
                inputs: {
                    ...this.state.te.inputs,
                    [type]: value,
                },
                show_results: false,
            }
        })
    }

    handleTESubmit() {
        // var url = 'http://localhost:8080/api/teavar';
        var url = 'http://128.30.92.156:8080/api/teavar';

        let data = {
            topology: this.state.te.inputs.topology,
            demand: this.state.te.inputs.demand,
            path: this.state.te.inputs.path,
            beta: this.state.te.inputs.beta,
            cutoff: this.state.te.inputs.cutoff,
        }
        if (this.state.te.inputs.path.includes("ksp")) {
            data.k = `${this.state.te.inputs.path.split("_")[1]}`;
        } else {
            data.k = "4";
        }
        switch (data.topology) {
            case "Custom":
                data.downscale_demand = "1";
                break;
            case "B4":
                data.downscale_demand = "1";
                break;
            case "IBM":
                data.downscale_demand = "1000";
                break;
            case "Abilene":
                data.downscale_demand = "1";
                break;
            default:
                data.downscale_demand = "1000";
                break;
        }

        fetch(url, {
          method: "POST",
          mode: "cors",
          body: JSON.stringify(data),
          headers:{
            'Content-Type': 'application/json'
          }
        }).then(res => res.json())
        .then(response => {
            console.log(response)
            this.setState({
                ...this.state,
                te: {
                    ...this.state.te,
                    inputs: {
                        ...this.state.te.inputs,
                        num_nodes: data.num_nodes,
                        zeroindex: data.zeroindex,
                    },
                    results: response,
                    show_results: true,
                },
            })
        })
        .catch(error => console.error('Error:', error));
    }

    render() {
        var home;
        var header;
        if (this.state.mode === "TE") {
            header = (<Header
                modes={["TE", "Stocks"]}
                mode={this.state.mode}
                setMode={this.setMode}
            />)
            home = (
                <div>
                    <TESection>
                        <div id="inputs">
                            <TEInputs
                              handleTESubmit={this.handleTESubmit}
                              handleTEInput={this.handleTEInput}>
                            </TEInputs>
                        </div>
                        <div id="graph">
                            {/*<img alt="graph" src={`./img/${this.state.te.inputs.topology}.png`}/>*/}
                            <ForceGraph
                                topology={this.state.te.inputs.topology}
                                num_nodes={this.state.te.results.num_nodes}
                                capacity={this.state.te.results.capacity}
                                failure_probabilities={this.state.te.results.failure_probabilities}
                                T={this.state.te.results.T}
                                Tf={this.state.te.results.Tf}
                                links={this.state.te.results.links}
                                flows={this.state.te.results.flows}
                                allocation={this.state.te.results.allocation}
                                demand={this.state.te.results.demand}
                                probabilities={this.state.te.results.probabilities}
                                scenarios={this.state.te.results.scenarios}
                                X={this.state.te.results.X}
                                var={this.state.te.results.var}
                                cvar={this.state.te.results.cvar}
                            />
                        </div>
                    </TESection>
                    {/**this.state.te.show_results &&
                        <TEOutputs
                          data={this.state.te.results}
                          num_nodes={this.state.te.inputs.num_nodes}
                          zeroindex={this.state.te.inputs.zeroindex}
                        />**/
                    }
                </div>
            )
        } else if (!this.state.login) {
            home = <Login login={this.login} />
            header = (<Header
                modes={["TE", "Stocks"]}
                mode={this.state.mode}
                setMode={this.setMode}
            />)
        } else  {
            header = (<Header
                modes={["TE", "Stocks"]}
                mode={this.state.mode}
                setMode={this.setMode}
            />)
            home = (<div>
                <StockInputs
                    handleTickerValue={this.handleTickerValue}
                    handleStockInput={this.handleStockInput}
                    handleAddTicker={this.handleAddTicker}
                    handleTickerSubmit={this.handleTickerSubmit}
                    tickers={this.state.stocks.inputs.tickers}
                    tickerMatches={this.state.stocks.tickerMatches}
                >
                </StockInputs>
                {this.state.stocks.show_results &&
                    <StockOutputs
                    data={this.state.stocks.results}
                    roi={parseFloat(this.state.stocks.inputs.roi)}
                    target={parseFloat(this.state.stocks.inputs.target)}
                    tickers={this.state.stocks.tickers}
                    budget={parseFloat(this.state.stocks.inputs.budget)}
                    />
                }
                </div>)
        }
        return (
          <div>
            { header }
            {this.state.error !== "" &&
                <StyledError onClick={this.removeError}>{this.state.error.message}</StyledError>
            }
            { home }
          </div>
        );
    }
}

export default App;
