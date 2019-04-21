//
//  ViewController.swift
//  benford
//
//  Created by 許光毅 on 2016/12/30.
//  Copyright © 2016年 GuangYihSheu. All rights reserved.
//

import UIKit

import MessageUI

class ViewController: UIViewController,MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var usersegment: UISegmentedControl!
    @IBOutlet weak var usertextfield: UITextField!

    @IBOutlet weak var userbutton: UIButton!
   
    @IBOutlet weak var userbutton1: UIButton!
        
    @IBOutlet weak var usertextview: UITextView!
    
    var chi_critical1=13.362
    var chi_critical2=106.469
    var kscritical = 1.22
    var kucritical = 1.62
    var significant = 0
    
    @IBAction func indexchanged(_ sender: Any) {
        significant = usersegment.selectedSegmentIndex
        switch usersegment.selectedSegmentIndex
        {
        case 0:
            self.chi_critical1=13.362
            self.chi_critical2=106.469
            self.kscritical=1.22
            self.kucritical=1.62
        case 1:
            self.chi_critical1=15.507
            self.chi_critical2=112.022
            self.kscritical=1.36
            self.kucritical=1.747
        case 2:
            self.chi_critical1=20.090
            self.chi_critical2=122.942
            self.kscritical=1.63
            self.kucritical=2.001
        case 3:
            self.chi_critical1=26.124
            self.chi_critical2=135.978
            self.kscritical=1.95
            self.kucritical=2.303
        default:
            self.chi_critical1=13.362
            self.chi_critical2=106.469
            self.kscritical=1.22
            self.kucritical=1.62
        }
    }
    @IBAction func sendemailpress(_ sender: Any) {
        let alert = UIAlertController(title: "E-mail Address", message: "Input an e-mail address", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.text = "xsheu@hotmail.com"
            textField.isSecureTextEntry = false // for password input
        })
        let textemail=alert.textFields![0]
        self.present(alert, animated: true, completion: nil)
         if(MFMailComposeViewController.canSendMail()) {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients([textemail.text!])
            mailComposer.setSubject("Conformity Evaluation Result")
            mailComposer.setMessageBody(self.usertextview.text, isHTML: false)
            self.present(mailComposer, animated: true, completion: nil)
        }
        
    }
    @IBAction func userbuttonpress(_ sender: Any) {
        // Button press event
        let url=usertextfield.text!
        if url=="http://" {
            let alert = UIAlertController(title: "Error", message: "The URL of an XBRL instance document is not input.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            var pdf = Array(repeating: 0.0, count: 99)
            var cumu = Array(repeating: 0.0, count: 99)
            var cumu_benford = Array(repeating: 0.0, count: 99)
            var total = 0.0
            var MAD = 0.0
            var chi = 0.0
            var MAD2d = 0.0
            var chi2d = 0.0
            var KolmogorovSmirnov2d = 0.0
            var KolmogorovSmirnov = 0.0
            var Kuiper_f = 0.0
            var Kuiper_f2d = 0.0
            var Kuiper_s = 0.0
            var Kuiper_s2d = 0.0
            let file = NSURL(string: url)
            let request = NSMutableURLRequest(url:(file!) as URL);
            request.httpMethod="GET"
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data,response,error in
                if error != nil
                {
                    DispatchQueue.main.async {
                        self.usertextview.text=error as! String!
                    }
                }
                let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                let seperated = responseString?.components(separatedBy: "<")
                DispatchQueue.main.async {
                    self.usertextview.isEditable=true
                    self.usertextview.text = "Conformity Evaluation Result"+"\n"
                }
                for lines in seperated! {
                    if(lines.contains(">") && !lines.contains("identifier")){
                        let piece=lines.components(separatedBy: ">")
                        for datatosearch in piece {
                           let digitdata = Float32(datatosearch)
                            if (digitdata != nil) {
                                if (abs(digitdata!)>10.0) {
                                    total += 1
                                    if(digitdata! > 0) {
                                        let first=String(datatosearch[datatosearch.startIndex])
                                        let firsttwo=String(datatosearch[..<datatosearch.index(datatosearch.startIndex, offsetBy: 2)])
                                        let firsti = Int(first)
                                        pdf[firsti!-1] += 1.0
                                        let firsttwoi = Int(firsttwo)
                                        pdf[firsttwoi!-1] += 1.0
                                        
                                    }
                                    else {
                                        let stringtodigit=String(datatosearch[datatosearch.index(datatosearch.startIndex, offsetBy: 1)...])
                                        if(stringtodigit.startIndex != stringtodigit.endIndex) {
                                            let first=String(stringtodigit[stringtodigit.startIndex])
                                            let firsttwo=String(stringtodigit[..<stringtodigit.index(stringtodigit.startIndex, offsetBy: 2)])
                                            let firsti = Int(first)
                                            pdf[firsti!-1] += 1.0
                                            let firsttwoi = Int(firsttwo)
                                            pdf[firsttwoi!-1] += 1.0
                                        }
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                for n in 1...99 {
                    pdf[n-1] /= total
                }
                print(total)
                DispatchQueue.main.async {
                    let message = String("Total retrieved bins = "+String(total)+"\n"+"Leading Digital Probability"+"\n"+"==============================="+"\n")
                    self.usertextview.text.append(message)
                }
                for m in 1...9 {
                    var actual=0.0
                    var theoretical=0.0
                    for n in 1...m {
                        theoretical += self.benford_theoretical(digit: Double(n))
                        actual += pdf[n-1]
                    }
                    cumu[m-1] = actual
                    cumu_benford[m-1] = theoretical
                    let diff=self.benford_theoretical(digit: Double(m))-pdf[m-1]
                    let diffcumu=cumu_benford[m-1]-cumu[m-1];
                    MAD += Swift.abs(diff)
                    chi += diff*diff*total/self.benford_theoretical(digit: Double(m))
                    KolmogorovSmirnov=max(Swift.abs(diffcumu),Double(KolmogorovSmirnov))
                    Kuiper_f=max(diffcumu,Double(Kuiper_f))
                    Kuiper_s=max(-diffcumu,Double(Kuiper_s))
                    DispatchQueue.main.async {
                        var off=10
                        if((String(pdf[m-1])).count<10) {
                            off=0
                        }
                        let index = (String(pdf[m-1])).index((String(pdf[m-1])).startIndex, offsetBy: (String(pdf[m-1])).count-off)
                        let message = String("Digit "+String(m)+" = "+String(String(pdf[m-1])[..<index])+"\n")
                        self.usertextview.text.append(message)
                    }
                }
                
                MAD=MAD/9.0
                DispatchQueue.main.async {
                    let outputstring=self.MADoutput(mad1d: MAD)
                    var rx=String(MAD).endIndex
                    if(String(MAD).count>5) {
                        rx=String(MAD).index((String(MAD)).startIndex, offsetBy: 5)
                    }
                    self.usertextview.text.append("Mean Absolute Deviation Test Statistics = "+String(String(MAD)[..<rx])+" ("+outputstring+")\n")
                    var ry = String(chi).endIndex
                    if(String(chi).count>5) {
                        ry=String(chi).index((String(chi)).startIndex, offsetBy: 5)
                    }
                    if chi>self.chi_critical1 {
                        self.usertextview.text.append("Chi-square Test Statistics = "+String(String(chi)[..<ry])+" (Unacceptable)\n")
                    }
                    else {
                        self.usertextview.text.append("Chi-square Test Statistics = "+String(String(chi)[..<ry])+" (Acceptable)\n")
                    }
                    let criticalks=self.kscritical/sqrt(total)
                    var rz = String(KolmogorovSmirnov).endIndex
                    if(String(KolmogorovSmirnov).count>5) {
                        rz = String(KolmogorovSmirnov).index((String(KolmogorovSmirnov)).startIndex, offsetBy: 5)
                    }
                    if KolmogorovSmirnov>criticalks {
                        self.usertextview.text.append("Kolmogorov_Smirnov Test Statistics = "+String(String(KolmogorovSmirnov)[..<rz])+" (Unacceptable)\n")
                    }
                    else {
                        self.usertextview.text.append("Kolmogorov_Smirnov Test Statistics = "+String(String(KolmogorovSmirnov)[..<rz])+" (Acceptable)\n")
                    }
                    let criticalku=self.kucritical/sqrt(total)
                    var rw = String(Kuiper_f+Kuiper_s).endIndex
                    if(String(Kuiper_f+Kuiper_s).count>5) {
                        rw=String(Kuiper_f+Kuiper_s).index((String(Kuiper_f+Kuiper_s)).startIndex, offsetBy: 5)
                    }
                    if Kuiper_f+Kuiper_s>criticalku {
                        self.usertextview.text.append("Kuiper Test Statistics = "+String(String(Kuiper_f+Kuiper_s)[..<rw])+" (Unacceptable)\n")
                    }
                    else {
                        self.usertextview.text.append("Kuiper Test Statistics = "+String(String(Kuiper_f+Kuiper_s)[..<rw])+" (Acceptable)\n")
                    }
                    self.usertextview.text.append("===============================\n")
                    self.usertextview.text.append("First-two Digital Probability\n")
                    self.usertextview.text.append("===============================\n")
                }
                for m in 10...99 {
                    var actual2d = 0.0
                    var theoretical2d = 0.0
                    for n in 10...m {
                        theoretical2d += self.benford_theoretical(digit: Double(n))
                        actual2d += pdf[n-1]
                    }
                    cumu[m-1]=actual2d
                    cumu_benford[m-1] = theoretical2d
                    let diff=self.benford_theoretical(digit: Double(m))-pdf[m-1]
                    let diffcumu2d=cumu_benford[m-1]-cumu[m-1];
                    MAD2d += Swift.abs(diff)
                    chi2d += diff*diff*total/self.benford_theoretical(digit: Double(m))
                    KolmogorovSmirnov2d = max(Swift.abs(diffcumu2d),Double(KolmogorovSmirnov2d))
                    Kuiper_f2d = max(diffcumu2d,Double(Kuiper_f2d))
                    Kuiper_s2d = max(-diffcumu2d,Double(Kuiper_s2d))
                    DispatchQueue.main.async {
                        var off=10
                        if((String(pdf[m-1])).count<10) {
                            off=0
                        }
                        let index = (String(pdf[m-1])).index((String(pdf[m-1])).startIndex, offsetBy: (String(pdf[m-1])).count-off);
                        let message = String("Digits "+String(m)+" = "+String(String(pdf[m-1])[..<index])+"\n")
                        self.usertextview.text.append(message)
                    }
                }
                MAD2d=MAD2d/90
                DispatchQueue.main.async {
                    let outputstring = self.MADoutput2d(mad2d: MAD2d)
                    var rx=String(MAD2d).endIndex
                    if(String(MAD2d).count>5) {
                        rx=String(MAD2d).index((String(MAD2d)).startIndex, offsetBy: 5)
                    }
                    self.usertextview.text.append("Mean Absolute Deviation Test Statistics = "+String(String(MAD2d)[..<rx])+" ("+outputstring+")\n")
                    var ry = String(chi2d).endIndex
                    if(String(chi2d).count>5) {
                        ry=String(chi2d).index((String(chi2d)).startIndex, offsetBy: 5)
                    }
                    if chi2d>self.chi_critical2 {
                        self.usertextview.text.append("Chi-square Test Statistics = "+String(String(chi2d)[..<ry])+" (Unacceptable)\n")
                    }
                    else {
                        self.usertextview.text.append("Chi-square Test Statistics = "+String(String(chi2d)[..<ry])+" (Acceptable)\n")
                    }
                    let criticalks2d=self.kscritical/sqrt(total)
                    var rz = String(KolmogorovSmirnov2d).endIndex
                    if(String(KolmogorovSmirnov2d).count>5) {
                        rz = String(KolmogorovSmirnov2d).index((String(KolmogorovSmirnov2d)).startIndex, offsetBy: 5)
                    }
                    if KolmogorovSmirnov2d>criticalks2d {
                        self.usertextview.text.append("Kolmogorov_Smirnov Test Statistics = "+String(String(KolmogorovSmirnov2d)[..<rz])+" (Unacceptable)\n")
                    }
                    else {
                        self.usertextview.text.append("Kolmogorov_Smirnov Test Statistics = "+String(String(KolmogorovSmirnov2d)[..<rz])+" (Acceptable)\n")
                    }
                    let criticalku2d=self.kucritical/sqrt(total)
                    var rw = String(Kuiper_f2d+Kuiper_s2d).endIndex
                    if(String(Kuiper_f2d+Kuiper_s2d).count>5) {
                        rw=String(Kuiper_f2d+Kuiper_s2d).index((String(Kuiper_f2d+Kuiper_s2d)).startIndex, offsetBy: 5)
                    }
                    if Kuiper_f2d+Kuiper_s2d>criticalku2d {
                        self.usertextview.text.append("Kuiper Test Statistics = "+String(String(Kuiper_f2d+Kuiper_s2d)[..<rw])+" (Unacceptable)\n")
                    }
                    else {
                        self.usertextview.text.append("Kuiper Test Statistics = "+String(String(Kuiper_f2d+Kuiper_s2d)[..<rw])+" (Acceptable)\n")
                    }
                    self.usertextview.text.append("===============================\n")
                    self.userbutton1.isEnabled=true
                    self.userbutton1.setTitleColor(UIColor.black, for: UIControlState.normal)
                    self.usersegment.selectedSegmentIndex = self.significant
                    print(self.usertextview.text)
                }
                
            }
            task.resume()
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        usertextfield.text="https://www.xbrl.org/taxonomy/int/fr/ias/ci/pfs/2002-11-15/Novartis-2002-11-15.xml"
//        usertextfield.text="http://xbrl.squarespace.com/storage/examples/HelloWorld.xml"

        //example1
        //        usertextfield.text="http://wwwimages.adobe.com/content/dam/acom/en/investor-relations/xbrl/adbe-20100305.xml"
 //       usertextfield.text="http://wwwimages.adobe.com/content/dam/acom/en/investor-relations/xbrl/adbe-20100604.xml"
//        usertextfield.text="http://wwwimages.adobe.com/content/dam/acom/en/investor-relations/xbrl/adbe-20100903.xml"
//        usertextfield.text="http://balchem.com/sites/default/files/bcpc-20170331.xml"
//        usertextfield.text="http://wwwimages.adobe.com/content/dam/acom/en/investor-relations/xbrl/adbe-20101203.xml"
        
//         usertextfield.text="http://xsheu.kissr.com/2015Q11.xml"
//         usertextfield.text="http://xsheu.kissr.com/2015Q12.xml"
//        usertextfield.text="http://xsheu.kissr.com/2015Q13.xml"
 //         usertextfield.text="http://freexsheu.droppages.com/2015Q12.xml"
  //        usertextfield.text="http://freexsheu.droppages.com/2015Q13.xml"
//      usertextfield.text="http://freexsheu.droppages.com/2015Q14.xml"
        usertextfield.text="http://freexsheu.droppages.com/2015Q11.xml"

//        usertextfield.text="http://freexsheu.droppages.com/1301Q2.xml"
 //       usertextfield.text="http://freexsheu.droppages.com/2002Q2.xml"
//        usertextfield.text="http://freexsheu.droppages.com/2330Q2.xml"
//        usertextfield.text="http://freexsheu.droppages.com/2357Q2.xml"



        
//        usertextfield.text="http://freexsheu.droppages.com/2013Q1.xml"
//        usertextfield.text="http://freexsheu.droppages.com/2013Q2.xml"
//        usertextfield.text="http://freexsheu.droppages.com/2013Q3.xml"
//        usertextfield.text="http://freexsheu.droppages.com/2013Q4.xml"


        userbutton1.isEnabled=false
        userbutton1.setTitleColor(UIColor.white, for: UIControlState.disabled)
        usertextview.isEditable=false
        userbutton1.layer.cornerRadius = 4
        userbutton.layer.cornerRadius = 4
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func benford_theoretical(digit: Double)->Double {
        return log10((digit+1.0)/digit)
    }
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
    func MADoutput(mad1d: Double)->String {
        var outputstring: String = ""
        if mad1d<=0.006 {
            outputstring="Close"
        }
        else {
            if mad1d<=0.012 {
                outputstring="Acceptable"
            }
            else {
                if mad1d<=0.015 {
                    outputstring="Marginally Acceptable"
                }
                else {
                    outputstring="Unacceptable"
                }
            }
        }
        return outputstring
    }
    func MADoutput2d(mad2d: Double)->String {
        var outputstring: String = ""
        if mad2d<=0.012 {
            outputstring="符合度：佳"
        }
        else {
            if mad2d<=0.018 {
                outputstring="符合度：可"
            }
            else {
                if mad2d<=0.022 {
                    outputstring="符合度：尚可"
                }
                else {
                    outputstring="符合度：差"
                }
            }
        }
        return outputstring
    }

}

