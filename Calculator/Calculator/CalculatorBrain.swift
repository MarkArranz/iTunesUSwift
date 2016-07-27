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
    private var descriptionAccumulator = ""
    private var internalProgram = [AnyObject]()
    
    var description: String {
        get {
            if !isPartialResult {
                return descriptionAccumulator
            } else {
                return pending!
                    .descriptionFunction(
                        pending!.descriptionOperand,
                        pending!.descriptionOperand != descriptionAccumulator
                            ? descriptionAccumulator
                            : ""
                )
            }
        }
    }
    
    var isPartialResult: Bool {
        get {
            return pending != nil
        }
    }
    
    func setOperand(operand: Double) {
        accumulator = operand
        descriptionAccumulator = String(format: "%g", operand)
        internalProgram.append(operand)
    }
    
    func setOperand(variableName: String) {
        descriptionAccumulator = variableName
        internalProgram.append(variableName)
        if let existingValue = variableValues[variableName] {
            accumulator = existingValue
        } else {
            variableValues[variableName] = 0.0
        }
    }
    
    var variableValues: Dictionary<String, Double> = [:] {
        didSet {
            program = internalProgram
        }
    }
    
    func undo() -> String {
        let operand: Double
        var count = 0
        var lastInput: AnyObject?
        var operation: String?
        
        repeat {
            count += 1
            lastInput = internalProgram.popLast()
            operation = lastInput as? String
        } while (operation != nil && operations.keys.contains(operation!))
        
        if operation != nil {
            operand = variableValues[operation!] ?? 0.0
            if count > 1 {
                /*  
                 Re-append the variable if it wasn't the last input
                 when undo() was first called. This ensures the
                 description display on the calculator is correct.
                */
                internalProgram.append(lastInput!)
            }
        } else {
            operand = lastInput as? Double ?? 0.0
        }
        
        program = internalProgram
        return String(format: "%g", operand)
    }
    
    private var operations: Dictionary<String,Operation> = [
        "π" : Operation.Constant(M_PI),
        "e" : Operation.Constant(M_E),
        "√" : Operation.UnaryOperation(sqrt, { "√(\($0))" }),
        "x²" : Operation.UnaryOperation({ $0 * $0 }, { "\($0)²" }),
        "sin" : Operation.UnaryOperation(sin, { "sin(\($0))" }),
        "cos" : Operation.UnaryOperation(cos, { "cos(\($0))" }),
        "tan" : Operation.UnaryOperation(tan, { "tan(\($0))" }),
        "x^y" : Operation.BinaryOperation(pow, { "\($0)^\($1)" }),
        "×" : Operation.BinaryOperation({ $0 * $1 }, { "\($0) × \($1)" }),
        "÷" : Operation.BinaryOperation({ $0 / $1 }, { "\($0) ÷ \($1)" }),
        "+" : Operation.BinaryOperation({ $0 + $1 }, { "\($0) + \($1)" }),
        "−" : Operation.BinaryOperation({ $0 - $1 }, { "\($0) − \($1)" }),
        "=" : Operation.Equals,
        "c" : Operation.Clear
    ]
    
    private enum Operation {
        case Constant(Double)
        case UnaryOperation((Double) -> Double, (String) -> String)
        case BinaryOperation((Double, Double) -> Double, (String, String) -> String)
        case Equals
        case Clear
    }
    
    func performOperation(symbol: String) {
        internalProgram.append(symbol)
        if let operation = operations[symbol] {
            switch operation {
            case .Constant(let value):
                accumulator = value
            case .UnaryOperation(let function, let descriptionFunction):
                accumulator = function(accumulator)
                descriptionAccumulator = descriptionFunction(descriptionAccumulator)
            case .BinaryOperation(let function, let descriptionFunction):
                executePendingBinaryOperation()
                pending = pendingBinaryOperationInfo(
                    binaryFunction: function,
                    firstOperand: accumulator,
                    descriptionFunction: descriptionFunction,
                    descriptionOperand: descriptionAccumulator
                )
            case .Equals:
                executePendingBinaryOperation()
            case .Clear:
                clear()
                clearVariables()
            }
        }
    }
    
    private func executePendingBinaryOperation() {
        if pending != nil {
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            descriptionAccumulator = pending!.descriptionFunction(
                pending!.descriptionOperand,
                descriptionAccumulator
            )
            pending = nil
        }
    }
    
    private var pending: pendingBinaryOperationInfo?
    
    private struct pendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
        var descriptionFunction: (String, String) -> String
        var descriptionOperand: String
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
                    } else if let keyOrOperation = op as? String {
                        if variableValues.keys.contains(keyOrOperation) {
                            setOperand(keyOrOperation)
                        } else {
                            performOperation(keyOrOperation)
                        }
                    }
                }
            }
        }
    }
    
    func clear() {
        accumulator = 0.0
        descriptionAccumulator = ""
        pending = nil
        internalProgram.removeAll()
    }
    
    func clearVariables() {
        variableValues.removeAll()
    }
    
    var result: Double {
        get {
            return accumulator
        }
    }
}