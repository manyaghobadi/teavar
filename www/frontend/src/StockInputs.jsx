import React, { Component } from 'react';
import styled from 'styled-components';


const StyledInputs = styled.div`
    margin 40px auto;
    text-align: center;

    form {
        margin: 10px;
        select {
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
         font-size: inherit;
         overflow: hidden;
         padding: 5px 10px;
         text-overflow: ellipsis;
         white-space: nowrap;
         width: 300px;
        }
    }


    .input {
      text-align: center;
      width: 100%;
      display: block;
      height: 50px;

      input {
        display: inline-block;
        border-left: none;
        border-right: 1px solid #AAA;
        border-top: 1px solid #AAA;
        border-bottom: 1px solid #AAA;
        border-top-left-radius: 0px;
        border-bottom-left-radius: 0px;
      }
    }

    .input_label {
      color: white;
      display: inline-block;
      width: 75px;
      height: calc(100% - 34px);
      background-color: #999;
      vertical-align: top;
      margin: 10px 0px;
      padding: 6px 10px;
      border-left: 1px solid #AAA;
      border-top: 1px solid #AAA;
      border-bottom: 1px solid #AAA;
      font-size: 14px;
    }

    input {
      position: relative;
      display: block;
      margin: 10px auto;
      -webkit-appearance: button;
      -webkit-border-radius: 2px;
      -webkit-box-shadow: 0px 1px 3px rgba(0, 0, 0, 0.1);
      -webkit-padding-end: 20px;
      -webkit-padding-start: 2px;
      -webkit-user-select: none;
      border: 1px solid #AAA;
      color: #555;
      font-size: inherit;
      overflow: hidden;
      padding: 5px 10px;
      text-overflow: ellipsis;
      white-space: nowrap;
      width: 278px;
    }
    .matches {
      position: relative;
      top: 10px;
    }
    button {
      margin: 10px;
    }
`;

class StockInputs extends Component {

    render() {
        const tickerInputs =
            this.props.tickers.map((ticker, num) => {
                return (
                    <input
                      key={num}
                      type="text"
                      placeholder={`Ticker ${num}`}
                      value={ticker}
                      onChange={e => this.props.handleTickerValue(e.target.value, num)}
                    />

                );
            });

        let matches
        if (this.props.tickerMatches) {
          matches = this.props.tickerMatches.map(ticker => (<div>{ticker["1. symbol"]}</div>))
        }

        return (
          <div>
            <StyledInputs>
              <div className="tickers_label">Portfolio Tickers</div>

                {tickerInputs}
              <div>
                {matches}
              </div>
              <button onClick={e => this.props.handleAddTicker()}>
                Add
              </button>
              <div className="input">
                <div className="input_label">Budget ($)</div>
                <input
                  type="text"
                  placeholder="1000"
                  onChange={e => this.props.handleStockInput(e.target.value, "budget")}
                />
              </div>
              <div className="input">
                <div className="input_label">Return ($)</div>
                <input
                  type="text"
                  placeholder="50"
                  onChange={e => this.props.handleStockInput(e.target.value, "roi")}
                />
              </div>
              <div className="input">
                <div className="input_label">Loss ($)</div>
                <input
                  type="text"
                  placeholder="40"
                  onChange={e => this.props.handleStockInput(e.target.value, "target")}
                />
              </div>
              {/*<input
                type="text"
                placeholder="1000"
                onChange={e => this.props.handleStockInput(e.target.value, "days")}
              />*/}
              <button onClick={e => this.props.handleTickerSubmit()}>
                Submit
              </button>
            </StyledInputs>
          </div>
        );
    }
}


export default StockInputs;
