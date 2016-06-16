//
//  WebServerUtilities.swift
//  phyphox
//
//  Created by Jonas Gessner on 15.04.16.
//  Copyright © 2016 Jonas Gessner. All rights reserved.
//  By Order of RWTH Aachen.
//

import Foundation

final class WebServerUtilities {
    class func genPlaceHolderImage() -> UIImage {
        let s = CGSizeMake(30, 30)
        
        UIGraphicsBeginImageContextWithOptions(s, true, 0.0)
        
        UIColor.greenColor().setFill()
        
        UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: s)).fill()
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return img
    }
    
    class func genPlaceHolderBase64Image() -> String {
        return UIImagePNGRepresentation(genPlaceHolderImage())!.base64EncodedStringWithOptions([])
    }
    
    private class func prepareStyleFile(backgroundColor backgroundColor: UIColor, lightBackgroundColor: UIColor, lightBackgroundHoverColor: UIColor, mainColor: UIColor, highlightColor: UIColor) -> String {
        let raw = try! NSMutableString(contentsOfFile: NSBundle.mainBundle().pathForResource("phyphox-webinterface/style", ofType: "css")!, encoding: NSUTF8StringEncoding)
        
        raw.replaceOccurrencesOfString("###background-color###", withString: "#" + backgroundColor.hexStringValue, options: [], range: NSMakeRange(0, raw.length))
        raw.replaceOccurrencesOfString("###background2-color###", withString: "#" + lightBackgroundColor.hexStringValue, options: [], range: NSMakeRange(0, raw.length))
        raw.replaceOccurrencesOfString("###background2hover-color###", withString: "#" + lightBackgroundHoverColor.hexStringValue, options: [], range: NSMakeRange(0, raw.length))
        
        raw.replaceOccurrencesOfString("###main-color###", withString: "#" + mainColor.hexStringValue, options: [], range: NSMakeRange(0, raw.length))
        
        raw.replaceOccurrencesOfString("###highlight-color###", withString: "#" + highlightColor.hexStringValue, options: [], range: NSMakeRange(0, raw.length))
        
        //These icons have been generated with the Android version of phyphox. Maybe, we should switch to a more flexible solution...?
        raw.replaceOccurrencesOfString("###drawablePlay###", withString: "iVBORw0KGgoAAAANSUhEUgAAAD8AAAA/CAYAAABXXxDfAAAABHNCSVQICAgIfAhkiAAAAUtJREFUaIHt12tRw1AUReETBgFIQAISKgEHBCXgAJxQFBQH4KA4IA4WP+AyQ/pIbnKfyf4EZM6ahm5qJiIiIiIiIoeAJ+Aq9x1Z8GMPbHLfkhz/vazqLeDQF3CX+64kjsQ7O+A6931RnYl3b8FD7hujGYh33oGb3LcGNzLeWdYsesbDkmZxQrxT/yzOiIfaZ3FmvLOjxlkMFA81zmLAeKeeWYwQ75Q/ixHjIeAsNiEe0gcQ47k9WzO7b5qmm/qAi4DHpHZrZntKm8XIr/0xj7mb/ySM7oB26p2XAZtTezWzds7ffBSRP+1PSv4RFDH8mRXu/Acr/A+vo6Rv8jEChb+xwl91s+YruxnhW0r/QhsyIbrs+fLhGV7+fPkYGV3PfPkYiK5vvnycCa9zvnyc+LTb3Hcl0Quvf758/EYvZ758sLT5EhERERERKdU3bpp4a7S0RxEAAAAASUVORK5CYII=", options: [], range: NSMakeRange(0, raw.length))
        raw.replaceOccurrencesOfString("###drawableTimedPlay###", withString: "iVBORw0KGgoAAAANSUhEUgAAAD8AAAA/CAYAAABXXxDfAAAABHNCSVQICAgIfAhkiAAAA7dJREFUaIHtW9tx2zAQXGTyH3YQdmCXwA7sVBCmAqsEd+B0ILkCqQMxFUiuQHIFoirYfIDKcOQ7EsSDlCfcTwq828XjCOBOwIwZM2b8JzBjOCGZAbgDcA8gA1AIzSoANYA9gDdjTD0GtyQgmZN8IrmjH7bN+/nUWpxB8qEhHhNbkg9Ta1NBsiB5iCz6GgeSxdRa/4FkRnKdWPQ11rRxJAhBAa8ZhTVsEHPBO4AjbFBrB7QMNhjmAL472qoB/DDGVI7t44E2GLlgQ7KkY+CiDZRl854LnhJL/UBw2UOoJvnsKrjDT97YqXv8LSNJ6yXUJ3zFCOvxymfG/pmQtgNILnpG+zGx/8eeWbBI5bjocLrnSJsR2qWw7+BSxHaYkTx1CI86zR35aB1wisqH+nd8dOEtTl0dsI7lRJvuNSfed9MuAS0GFDEcHBTjg4JbqhlCGwQlHFIZXnnY2pAsgwh12447+pRPZ7XPKJKsmveXsWcB7fqXpv/W12Cu9Oazp72qZWNH8t6LmG7/t8I39zGmbWiGG8MH8aT9JJU+thT72mAN3/gIZElyE0BOskdGXAaU13411EimEC0DiGniyUjLgPY0+AFa+y/Kc41IFUqww982pHMbVNJDKlF/iPh3Y8zRi5IbMgDLkGXQ8DsLP4mDqYmXnB99CHmghJ0FvstgLzwTO1MTXzgaTYWQZSDxLKSGmngJYycRfJeBM8+vwzmNjhL2orWMbXjIyE+FVwBJbmiGjPzY5/YzgIUxZjXwPWee2shXwrOoe/EevAEoPIQDMs9KaqiJl4KGazIhFK+wwn2/LnfCMzEIauIlxznT3tycAfwyxpS+6emGnzTtxY4cIh5QvpcREDLN2yiU5+7im55/E35KcS8fOs3bkPj9GTyTmP48X0c4yLTtRz3Pp7zJ2cc4wl7Zj3eTIxC+wCsp0LKVKpcnJVWqEKOf5fZWS6oUoYaPiuFbv7c/xjCuZWxOvI2MjZZDLGI50ZICu1Qj6sApo17m5n3RqjnScmKjd0CPcK+kSp/Drvz8juPm57sKG4tUjrsqM04cpzJDW+NkqsqMFoFVh3MyUo3clU+XWr9VTJ9dZPo64ETyhXGqsV56Rns84S1iXUugjTXJn64d0Qj+SfeqTu+pHqMCcwPgm+Mrl5JyrQLzUpLugjOAx0kqMC+gW41cbGw40f5CBO2nUNsKx8KRt1R1fQ3az1FXRtYH1U2LvgZt4FoEdETVvJ+n4jjmf2zaAa0QmlVoBcRP/R+bGTNmzLg1/AWXMEdyptzdlQAAAABJRU5ErkJggg==", options: [], range: NSMakeRange(0, raw.length))
        raw.replaceOccurrencesOfString("###drawablePause###", withString: "iVBORw0KGgoAAAANSUhEUgAAAD8AAAA/CAYAAABXXxDfAAAABHNCSVQICAgIfAhkiAAAAHtJREFUaIHtz7ENg0AQRNE9iwJcCiW4JVdCa3R0TghtCXMBOs178c5KvwoAAGBybWTce1+rajt5/m6t7Xf8/GW5Ojw8q+r1x+1dP796jIxnJz6V+FTiU4lPJT6V+FTiU4lPJT6V+FTiU4lPJT6V+FTiU4lPJR4AAIBJfQA9nAsMamJmWQAAAABJRU5ErkJggg==", options: [], range: NSMakeRange(0, raw.length))
        raw.replaceOccurrencesOfString("###drawableTimedPause###", withString: "iVBORw0KGgoAAAANSUhEUgAAAD8AAAA/CAYAAABXXxDfAAAABHNCSVQICAgIfAhkiAAAA2hJREFUaIHtW91Z4zAQHF8D5w7OHUAHpw7gKoAOoAQ6gA5IBwkVxFRAqCChgpgK5h6s3OcvtyuvE1kWd55H/e2MLK0i7QaYMWPGjP8ERQojJEsAFwAuAZQAnNCsBtAA2AB4L4qiScFtFJCsSN6RfONpWPv+1dRazCB55YnHxJrk1dTaVJB0JLeRRR9jS9JNrfUPSJYklyOLPsaSrR85C2c5PP8VlmidmAUfAHZonVrXoZVonWEF4IdxrAbAr6IoamP7eGDrjCxYkbyl0XGxdZS3vp8FdyNL/Yvgcw+hhuSDVXDATuXHaXrsPUeS1kuoT/iCEfbjkc2S/Sth3Akged/zta9Htn/dswruxzLsAkY3TPRjhO1W2AS4uNgGS5L7gPCoy9zIR5uAfVQ+1M/x5MI7nEITsIxlRFvuDSf+3c12C2g+wMUwsFUGH9W5WcHWCUrYjjXwIg71OKB+DLpzBl0LAzY07nMqW0ZpWwtNH4x2SsrLfx3q9y0wYAX50eEpt4cGz2chVDkG/JIqHoC2pyUjOeBJKVd901DxL0VR7IYwSgXP60WoGibe7+mfQtXqJGbpIPGTdADQv/ylUl4PZZMYtVSoef0h4j9yXfIHeH6fQpX4MTXx0lG2O41ScmyEMvFo1sQ746A5QuLppIYhb3+MrM72AMw8h4j/5zCLN2KSe/sJMPPUxNdCmXb25waJZy011MRLTsMaTJgaF0KZ6AQ18dJxUYVuSDnA85OWvXhMDxEPKOdlRnBKuV28vx+/C1VZPF0FIPF71d4fQt5+IZRd5br0PS8phq/eREPitU63dkpJoUVrhov3N6RXoerO+oaXCp7PjVD1evJNlF/n9VYLqrhzB94pA2fh/AIfaBdjcC1is5/a+bGN2GgxRBfLiBYUeOO0sTotzS3eWyP1oMAkE9Aj3BxUGWIwFJ9/Y9r4fCix0Y1lOJSZsWeazAxtj5NjZWZ0CCwCxslIOXJHNi25fouYNkNk+iZgT/KRcbKxHnu+djrhHWKhLdDFkuSNdSK84BvaszpPXuoxMjBXAL4buxxSyrUMzENKugWfAK4nycA8gLYcudhYMaf7BdujUPspHAs75pR1fQy2x5GUZXEO6qxFH4Ot47o/YyJq378ai2PK/9h0HZoTmtXoOMTcUl9mzJgx40vjNzmaRsZjF9NnAAAAAElFTkSuQmCC", options: [], range: NSMakeRange(0, raw.length))
        raw.replaceOccurrencesOfString("###drawableMore###", withString: "iVBORw0KGgoAAAANSUhEUgAAAD8AAAA/CAYAAABXXxDfAAAABHNCSVQICAgIfAhkiAAAAYBJREFUaIHt2uFtgzAQBeDnTpARPEI2KCN0BDZqNgjdoCOkEyQbhA3CBq8/4kgghdoS+K5B7/uHZIl3KOA7AiAiIiIi2xI8TkoyAngHEAH0AH5CCL1HFlMkD3zu0ztbVSS7mcIfjt4ZqyDZZAp/aKwyvVmdCEBbuO6jZogxy+Jj4bp9zRBjlsUPK69bzLL408rrXgfJHckh87AbSO68s1ZBcv/HBRhImt3vLkjGtN/3qeg+HUfvbCIim+U1z7eYzvOnEMKXRxYzqdE5z+zz5802OABA8pLp8M7eGasg2WYKf2itMlkONqVzelMzxJhl8aX3c6wZYsyy+H7ldYtpnrdS8LS/eGesJu3zcxfgYr3Pe3Z4DaYdXueRRUREauD97e2R5DVtcdd0HL2zVcX7e/vbzD5/41bf26cGZ67w8QUwa3Ss/6LOFbZD+V/Zi2me/2c2+bMvndjMJjvL4r9XXvdamP8aq/POWBXnv8M7WGfx/AKzwXSe7z2yiIiIiMiW/AKU60rEUati9QAAAABJRU5ErkJggg==", options: [], range: NSMakeRange(0, raw.length))
        
        return raw as String
    }
    
    private class func prepareIndexFile(experiment: Experiment) -> String {
        let raw = try! NSMutableString(contentsOfFile: NSBundle.mainBundle().pathForResource("phyphox-webinterface/index", ofType: "html")!, encoding: NSUTF8StringEncoding)
        
        raw.replaceOccurrencesOfString("<!-- [[title]] -->", withString: experiment.localizedTitle, options: [], range: NSMakeRange(0, raw.length))
        
        raw.replaceOccurrencesOfString("<!-- [[clearDataTranslation]] -->", withString: NSLocalizedString("clear_data", comment: ""), options: [], range: NSMakeRange(0, raw.length))
        raw.replaceOccurrencesOfString("<!-- [[exportTranslation]] -->", withString: NSLocalizedString("export", comment: ""), options: [], range: NSMakeRange(0, raw.length))
        raw.replaceOccurrencesOfString("<!-- [[switchColumns1Translation]] -->", withString: NSLocalizedString("switchColumns1", comment: ""), options: [], range: NSMakeRange(0, raw.length))
        raw.replaceOccurrencesOfString("<!-- [[switchColumns2Translation]] -->", withString: NSLocalizedString("switchColumns2", comment: ""), options: [], range: NSMakeRange(0, raw.length))
        raw.replaceOccurrencesOfString("<!-- [[switchColumns3Translation]] -->", withString: NSLocalizedString("switchColumns3", comment: ""), options: [], range: NSMakeRange(0, raw.length))
        
        var viewLayout = "var views = ["
        var viewOptions = ""
        
        if let views = experiment.viewDescriptors {
            var idx = 0
            
            for (i, v) in views.enumerate() {
                if i > 0 {
                    viewLayout += ",\n"
                    viewOptions += "\n"
                }
                
                viewLayout += "{\"name\": \"\(v.localizedLabel)\", \"elements\": ["
                
                viewOptions += "<li>\(v.localizedLabel)</li>"
                
                var ffirst = true
                
                for element in v.views {
                    if !ffirst {
                        viewLayout += ", "
                    }
                    ffirst = false
                    
                    viewLayout += "{\"label\": \"\(element.localizedLabel)\", \"index\": \(idx), \"html\": \"\(element.generateViewHTMLWithID(idx))\",\"dataCompleteFunction\": \(element.generateDataCompleteHTMLWithID(idx))"

                    if let graph = element as? GraphViewDescriptor {
                        viewLayout += ", \"partialUpdate\": \"\(graph.partialUpdate ? "partial" : "full")\", \"dataYInput\": \"\(graph.yInputBuffer.name)\", \"dataYInputFunction\":\n\(graph.setDataYHTMLWithID(idx))\n"
                        
                        if let x = graph.xInputBuffer {
                            viewLayout += ", \"dataXInput\": \"\(x.name)\", \"dataXInputFunction\":\n\(graph.setDataXHTMLWithID(idx))\n"
                        }
                    }
                    else if element is InfoViewDescriptor {
                        viewLayout += ", \"partialUpdate\": \"none\""
                    }
                    else if let value = element as? ValueViewDescriptor {
                        viewLayout += ", \"partialUpdate\": \"single\", \"valueInput\":\"\(value.buffer.name)\", \"valueInputFunction\":\n\(value.setValueHTMLWithID(idx))\n"
                    }
                    else if let edit = element as? EditViewDescriptor {
                        viewLayout += ", \"partialUpdate\": \"input\", \"valueInput\":\"\(edit.buffer.name)\", \"valueInputFunction\":\n\(edit.setValueHTMLWithID(idx))\n"
                    }
                    
                    viewLayout += "}"
                    
                    idx += 1
                }
                
                viewLayout += "]}"
            }
        }
        
        viewLayout += "];\n"
        
        /*var exportStr = ""
        
        if let export = experiment.export {
            for (i, set) in export.sets.enumerate() {
                exportStr += "<div class=\"setSelector\"><input type=\"checkbox\" id=\"set\(i)\" name=\"set\(i)\" /><label for=\"set\(i)\"\">\(set.localizedName)</label></div>\n"
            }
        }*/
       
        
        var exportFormats = ""
        for (i, format) in exportTypes.enumerate() {
            exportFormats += "<option value=\"\(i)\">\(format.0)</option>"
        }
        
        
        raw.replaceOccurrencesOfString("<!-- [[viewLayout]] -->", withString: viewLayout, options: [], range: NSMakeRange(0, raw.length))
        raw.replaceOccurrencesOfString("<!-- [[viewOptions]] -->", withString: viewOptions, options: [], range: NSMakeRange(0, raw.length))
        raw.replaceOccurrencesOfString("<!-- [[exportFormatOptions]] -->", withString: exportFormats, options: [], range: NSMakeRange(0, raw.length))
        //raw.replaceOccurrencesOfString("<!-- [[exportSetSelectors]] -->", withString: exportStr, options: [], range: NSMakeRange(0, raw.length))
        
        return raw as String
    }
    
    class func mapFormatString(str: String) -> ExportFileFormat? {
        return exportTypes[Int(str) ?? 0].1
    }
    
    class func prepareWebServerFilesForExperiment(experiment: Experiment) -> String {
        let path = NSTemporaryDirectory() + "/" + NSUUID().UUIDString
        
        try! NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
        
        let css = prepareStyleFile(backgroundColor: kBackgroundColor, lightBackgroundColor: kLightBackgroundColor, lightBackgroundHoverColor: kLightBackgroundHoverColor, mainColor: kTextColor, highlightColor: kHighlightColor)
        
        let html = prepareIndexFile(experiment)
        
        try! css.writeToFile(path + "/style.css", atomically: true, encoding: NSUTF8StringEncoding)
        try! html.writeToFile(path + "/index.html", atomically: true, encoding: NSUTF8StringEncoding)
        
        return path
    }
}