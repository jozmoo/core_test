--[[
/* Copyright (C) 2015 SAS Institute Inc. Cary, NC, USA */

/*!
\file    fx_quote.lua

\brief   Given report currency, use Bellman-Ford algorithm to find optimized FX spot quote

\ingroup commonAnalytics

\author  SAS Institute Inc.

\date    2015

\PRECONDITION:  Requires enriched output from irm_b10_proc_mkt_fx


*/

]]

local errors = require 'sas.risk.utils.errors'
local sas_msg = require 'sas.risk.utils.sas_msg'
local risk = require 'luarisk.risk'
local graph = require 'luastl.graph'

local M = {}

-- declare function
local loadFXQuote
local getOptimizedFXQuote
local createOptimizedFXQuoteDataset

-- load FX spot quote data set into table
loadFXQuote = function (in_FX_Spot_Quote_ds)

    local base_currency, quote_currency, quote_rt

    local FX_Quote_Data = {}

    if sas.exists(in_FX_Spot_Quote_ds) == false then
        errors.throw("rsk_ds_not_found_error", in_FX_Spot_Quote_ds)
    end

    --Open spot FX rate--
    local spot_fx_dsid = sas.open(in_FX_Spot_Quote_ds,"i")

    --Load FX spot quote data set--
    while sas.next(spot_fx_dsid) do

        base_currency = sas.get_value(spot_fx_dsid,"FROM_CURRENCY_CD")
        quote_currency = sas.get_value(spot_fx_dsid,"TO_CURRENCY_CD")
        quote_rt = sas.get_value(spot_fx_dsid,"QUOTE_RT")

        if FX_Quote_Data[base_currency] == nil then
            FX_Quote_Data[base_currency] = {}
        end

        if FX_Quote_Data[quote_currency] == nil then
            FX_Quote_Data[quote_currency] = {}
        end

        FX_Quote_Data [base_currency][quote_currency] = quote_rt

    end

    sas.close(spot_fx_dsid)

    return FX_Quote_Data

end

-- Get optimized FX quote data
getOptimizedFXQuote = function(FX_Quote_Data, report_currency, rounding_error)

    local graphFX = graph.NewGraph()

    graphFX.setGraphMatrix(FX_Quote_Data)

    local FXQuote = risk.newFXQuote()

    FXQuote.setFXQuoteGraph(graphFX)

    FXQuote.convertCompleteFXQuote()

    local arbitrageNotExist, optimized_quotes_graph = FXQuote.getOptimizedFXQuote(report_currency, rounding_error)

    -- arbitrage opportunity exists
    if arbitrageNotExist == false then
        --print out warning
        sas_msg.print("rsk_fx_arbitrage_exist")

        local bfs_quotes_graph, _ = FXQuote.getBFSFXQuote(report_currency)

        return bfs_quotes_graph

    else

        return optimized_quotes_graph

    end
end

-- Create optimized FX quote data
createOptimizedFXQuoteDataset = function(in_FX_Spot_Quote_ds, out_FX_Spot_Quote_ds, in_report_currency, in_rounding_error)

    local FX_Quote_Data = loadFXQuote(in_FX_Spot_Quote_ds)

    local rounding_error = nil

    if in_rounding_error ~= nil then

      rounding_error = tonumber(in_rounding_error)

    end

    local optimized_quotes_graph = getOptimizedFXQuote(FX_Quote_Data, in_report_currency, rounding_error)

    -- transform graph into table
    local output_quote = {}
    local base_currency, quote_currency, quote, i
    i = 1
    for base_currency, quote_currency, quote in optimized_quotes_graph.allEdges() do

        if base_currency ~= quote_currency then
            output_quote[i] = {
                                ["BASE_CURRENCY"]   =   base_currency,
                                ["QUOTE_CURRENCY"]  =   quote_currency,
                                ["QUOTE"]           =   quote
                              }

            i = i + 1

        end

    end
    -- generate optimized FX quote data set
    sas.write_ds(output_quote, out_FX_Spot_Quote_ds)

end

M.createOptimizedFXQuoteDataset = createOptimizedFXQuoteDataset

return M
