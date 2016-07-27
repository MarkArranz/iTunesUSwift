//
//  ViewController.swift
//  Calculator
//
//  Created by Mark Arranz on 6/24/16.
//  Copyright © 2016 Mark Arranz. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet private weak var display: UILabel! // <- implicitly unwrapped optional
    @IBOutlet private weak var descriptionDisplay: UILabel!
    
    private var userIsInTheMiddleOfTyping = false
    
    @IBAction private func touchDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        if userIsInTheMiddleOfTyping {
            let textCurrentlyInDisplay = display.text!
            if digit != "." || !textCurrentlyInDisplay.containsString(".") {
                display.text = textCurrentlyInDisplay + digit
            }
        } else {
            display.text = digit
        }
        userIsInTheMiddleOfTyping = true
    }
    
    private var displayValue: Double {
        get {
            return Double(display.text!)!
        }
        set {
            display.text = String(format: "%g", newValue)
            descriptionDisplay.text = brain.description.isEmpty
                ? " "
                : brain.description + (brain.isPartialResult ? " ..." : " =")
        }
    }
    
    private var brain = CalculatorBrain()
    
    @IBAction private func performOperation(sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            brain.setOperand(displayValue)
            userIsInTheMiddleOfTyping = false
        }
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        displayValue = brain.result
    }
    
    @IBAction func setVariable(sender: UIButton) {
        userIsInTheMiddleOfTyping = false
        brain.variableValues["M"] = displayValue
        displayValue = brain.result
    }
    
    @IBAction func createVariable(sender: UIButton) {
        brain.setOperand(sender.currentTitle!)
        displayValue = brain.result
    }
    
    @IBAction func touchUndo(sender: UIButton) {
        var newDisplayValue = ""
        
        if userIsInTheMiddleOfTyping {
            let digit = display.text!
            newDisplayValue = digit.substringToIndex(digit.endIndex.predecessor())
            newDisplayValue = newDisplayValue.isEmpty ? "0" : newDisplayValue
        } else {
            newDisplayValue = brain.undo()
            // Set displayValue to get correct description
            displayValue = brain.result
        }
        
        userIsInTheMiddleOfTyping = newDisplayValue == "0" ? false : true
        display.text = newDisplayValue
    }
}