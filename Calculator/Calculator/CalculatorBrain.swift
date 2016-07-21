//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Mark Arranz on 6/25/16.
//  Copyright © 2016 Mark Arranz. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    private var accumulator = 0.0
    private var internalProgram = [AnyObject]()
    
    func setOperand(operand: Double) {
        accumulator = operand
        internalProgram.append(operand)
        description.appendContentsOf(String(format: "%g", operand))
    }
    
    private var description = ""
    private var isPartialResult = false
    
    var getDescription: String {
        get {
            var endString = " "
            if isPartialResult {
                endString.appendContentsOf("...")
            } else if description.characters.count > 1 {
                endString.appendContentsOf("=")
            }
            return description + endString
        }
    }
    
    func clearDescription() {
        description = ""
    }

    private var operations: Dictionary<String,Operation> = [
        "π" : Operation.Constant(M_PI),
        "e" : Operation.Constant(M_E),
        "√" : Operation.PrefixUnaryOperation(sqrt),
        "x^2" : Operation.PostfixUnaryOperation({ $0 * $0 }),
        "sin" : Operation.PrefixUnaryOperation(sin),
        "cos" : Operation.PrefixUnaryOperation(cos),
        "tan" : Operation.PrefixUnaryOperation(tan),
        "x^y" : Operation.BinaryOperation(pow),
        "×" : Operation.BinaryOperation({ $0 * $1 }),
        "÷" : Operation.BinaryOperation({ $0 / $1 }),
        "+" : Operation.BinaryOperation({ $0 + $1 }),
        "−" : Operation.BinaryOperation({ $0 - $1 }),
        "=" : Operation.Equals,
        "c" : Operation.Clear
    ]
    
    private enum Operation {
        case Constant(Double)
        case PrefixUnaryOperation((Double) -> Double)
        case PostfixUnaryOperation((Double) -> Double)
        case BinaryOperation((Double, Double) -> Double)
        case Equals
        case Clear
    }
    
    func performOperation(symbol: String) {
        internalProgram.append(symbol)
        if let operation = operations[symbol] {
            switch operation {
            case .Constant(let value):
                accumulator = value
                description.appendContentsOf(" " + symbol + " ")
            case .PrefixUnaryOperation(let function):
                accumulator = function(accumulator)
            case .PostfixUnaryOperation(let function):
                accumulator = function(accumulator)
                if symbol == "x^2" {
                    description.appendContentsOf("^2 ")
                } else {
                    description.appendContentsOf(" \(symbol) ")
                }
            case .BinaryOperation(let function):
                executePendingBinaryOperation()
                pending = pendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator)
                if symbol == "x^y" {
                    description.appendContentsOf("^")
                } else {
                    description.appendContentsOf(" \(symbol) ")
                }
                isPartialResult = true
            case .Equals:
                executePendingBinaryOperation()
            case .Clear:
                clear()
            }
        }
    }
    
    private func executePendingBinaryOperation() {
        if pending != nil {
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            pending = nil
            isPartialResult = false
        }
    }
    
    private var pending: pendingBinaryOperationInfo?
    
    private struct pendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
    }
    
    typealias PropertyList = AnyObject
    
    var program: PropertyList {
        get {
            return internalProgram
        }
        
        set {
            clear()
            if let arrayOfOps = newValue as? [AnyObject] {
                for op in arrayOfOps {
                    if let operand = op as? Double {
                        setOperand(operand)
                    } else if let operation = op as? String {
                        performOperation(operation)
                    }
                }
            }
        }
    }
    
    func clear() {
        accumulator = 0.0
        pending = nil
        internalProgram.removeAll()
        description = ""
        isPartialResult = false
    }
    
    var result: Double {
        get {
            return accumulator
        }
    }
}