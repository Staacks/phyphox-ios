//
//  ExperimentPickerView.swift
//  phyphox
//
//  Created by Sebastian Staacks on 07.01.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import UIKit

protocol ExperimentReceiver {
    func experimentSelected(_ experiment: Experiment)
}

class ExperimentPickerDialogView: UIView, ExperimentReceiver {
    var backgroundView = UIView()
    var dialogView = UIView()
    var delegate: ExperimentController?
    let experimentPicker = ExperimentPickerViewController()
    
    convenience init(title: String, message: String, experiments: [URL], delegate: ExperimentController) {
        self.init(frame: UIScreen.main.bounds)
        setup(title: title, message: message, experiments: experiments, delegate: delegate)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented.")
    }
    
    func setup(title: String, message: String, experiments: [URL], delegate: ExperimentController) {
        self.delegate = delegate
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        dialogView.clipsToBounds = true
        dialogView.translatesAutoresizingMaskIntoConstraints = false
        dialogView.backgroundColor = UIColor.white
        dialogView.layer.cornerRadius = 6
        
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = UIColor.black
        backgroundView.alpha = 0.6
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelDialog)))
        addSubview(backgroundView)
        
        let titleFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = titleFont
        titleLabel.textAlignment = .center
        dialogView.addSubview(titleLabel)
        
        let separatorView = UIView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = UIColor.groupTableViewBackground
        dialogView.addSubview(separatorView)
        
        let messageFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = message
        messageLabel.font = messageFont
        messageLabel.textAlignment = .left
        dialogView.addSubview(messageLabel)
        
        let saveButton = UIButton()
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle(NSLocalizedString("open_save_all", comment: ""), for: .normal)
        saveButton.setTitleColor(UIColor.black, for: .normal)
        saveButton.addTarget(self, action: #selector(saveAll), for: .touchUpInside)
        dialogView.addSubview(saveButton)
        
        let separatorView2 = UIView()
        separatorView2.translatesAutoresizingMaskIntoConstraints = false
        separatorView2.backgroundColor = UIColor.groupTableViewBackground
        dialogView.addSubview(separatorView2)
        
        let cancelButton = UIButton()
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle(NSLocalizedString("cancel", comment: ""), for: .normal)
        cancelButton.setTitleColor(UIColor.black, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelDialog), for: .touchUpInside)
        dialogView.addSubview(cancelButton)
        
        addSubview(dialogView)
        
        experimentPicker.delegate = self
        experimentPicker.populate(experiments)
        experimentPicker.view.translatesAutoresizingMaskIntoConstraints = false
        dialogView.addSubview(experimentPicker.view)
        
        let margin: CGFloat = 8.0
        let outerMargin: CGFloat = 32.0
        
        self.addConstraint(NSLayoutConstraint(item: backgroundView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: backgroundView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: backgroundView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: backgroundView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: dialogView, attribute: .left, relatedBy: .equal, toItem: backgroundView, attribute: .left, multiplier: 1, constant: outerMargin))
        self.addConstraint(NSLayoutConstraint(item: dialogView, attribute: .right, relatedBy: .equal, toItem: backgroundView, attribute: .right, multiplier: 1, constant: -outerMargin))
        self.addConstraint(NSLayoutConstraint(item: dialogView, attribute: .top, relatedBy: .equal, toItem: backgroundView, attribute: .top, multiplier: 1, constant: outerMargin))
        self.addConstraint(NSLayoutConstraint(item: dialogView, attribute: .bottom, relatedBy: .equal, toItem: backgroundView, attribute: .bottom, multiplier: 1, constant: -outerMargin))
        
        dialogView.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .top, relatedBy: .equal, toItem: dialogView, attribute: .top, multiplier: 1, constant: margin))
        dialogView.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: dialogView, attribute: .left, multiplier: 1, constant: margin))
        dialogView.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .right, relatedBy: .equal, toItem: dialogView, attribute: .right, multiplier: 1, constant: -margin))
        
        dialogView.addConstraint(NSLayoutConstraint(item: separatorView, attribute: .top, relatedBy: .equal, toItem: titleLabel, attribute: .bottom, multiplier: 1, constant: margin))
        dialogView.addConstraint(NSLayoutConstraint(item: separatorView, attribute: .left, relatedBy: .equal, toItem: titleLabel, attribute: .left, multiplier: 1, constant: 0))
        dialogView.addConstraint(NSLayoutConstraint(item: separatorView, attribute: .right, relatedBy: .equal, toItem: titleLabel, attribute: .right, multiplier: 1, constant: 0))
        dialogView.addConstraint(NSLayoutConstraint(item: separatorView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 1))
        
        dialogView.addConstraint(NSLayoutConstraint(item: messageLabel, attribute: .top, relatedBy: .equal, toItem: separatorView, attribute: .bottom, multiplier: 1, constant: margin))
        dialogView.addConstraint(NSLayoutConstraint(item: messageLabel, attribute: .left, relatedBy: .equal, toItem: separatorView, attribute: .left, multiplier: 1, constant: margin))
        dialogView.addConstraint(NSLayoutConstraint(item: messageLabel, attribute: .right, relatedBy: .equal, toItem: separatorView, attribute: .right, multiplier: 1, constant: -margin))
        
        dialogView.addConstraint(NSLayoutConstraint(item: experimentPicker.view, attribute: .top, relatedBy: .equal, toItem: messageLabel, attribute: .bottom, multiplier: 1, constant: margin))
        dialogView.addConstraint(NSLayoutConstraint(item: experimentPicker.view, attribute: .left, relatedBy: .equal, toItem: messageLabel, attribute: .left, multiplier: 1, constant: 0))
        dialogView.addConstraint(NSLayoutConstraint(item: experimentPicker.view, attribute: .right, relatedBy: .equal, toItem: messageLabel, attribute: .right, multiplier: 1, constant: 0))
        
        dialogView.addConstraint(NSLayoutConstraint(item: saveButton, attribute: .top, relatedBy: .equal, toItem: experimentPicker.view, attribute: .bottom, multiplier: 1, constant: margin))
        dialogView.addConstraint(NSLayoutConstraint(item: saveButton, attribute: .left, relatedBy: .equal, toItem: experimentPicker.view, attribute: .left, multiplier: 1, constant: 0))
        dialogView.addConstraint(NSLayoutConstraint(item: saveButton, attribute: .right, relatedBy: .equal, toItem: experimentPicker.view, attribute: .right, multiplier: 1, constant: 0))
        
        dialogView.addConstraint(NSLayoutConstraint(item: separatorView2, attribute: .top, relatedBy: .equal, toItem: saveButton, attribute: .bottom, multiplier: 1, constant: margin))
        dialogView.addConstraint(NSLayoutConstraint(item: separatorView2, attribute: .left, relatedBy: .equal, toItem: saveButton, attribute: .left, multiplier: 1, constant: 0))
        dialogView.addConstraint(NSLayoutConstraint(item: separatorView2, attribute: .right, relatedBy: .equal, toItem: saveButton, attribute: .right, multiplier: 1, constant: 0))
        dialogView.addConstraint(NSLayoutConstraint(item: separatorView2, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 1))
        
        dialogView.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: .top, relatedBy: .equal, toItem: separatorView2, attribute: .bottom, multiplier: 1, constant: margin))
        dialogView.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: .left, relatedBy: .equal, toItem: separatorView2, attribute: .left, multiplier: 1, constant: 0))
        dialogView.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: .right, relatedBy: .equal, toItem: separatorView2, attribute: .right, multiplier: 1, constant: 0))
        
        dialogView.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: .bottom, relatedBy: .equal, toItem: dialogView, attribute: .bottom, multiplier: 1, constant: -margin))
        
    }
    
    func show(animated: Bool) {
        backgroundView.alpha = 0
        if var rootController = UIApplication.shared.delegate?.window??.rootViewController {
            while let presentedVC = rootController.presentedViewController {
                rootController = presentedVC
            }
            rootController.view.addSubview(self)
            rootController.addChildViewController(experimentPicker)
            experimentPicker.didMove(toParentViewController: rootController)
        }
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.backgroundView.alpha = 0.66
            })
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 10, options: UIViewAnimationOptions(rawValue: 0), animations: {
                self.dialogView.center = self.center
            }, completion: nil)
        } else {
            self.backgroundView.alpha = 0.66
            self.dialogView.center = self.center
        }
    }
    
    @objc func cancelDialog () {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func saveAll() {
        delegate?.addExperimentsToCollection(experimentPicker.getAllExperiments())
        dismiss(animated: true, completion: nil)
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.backgroundView.alpha = 0
            })
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 10, options: UIViewAnimationOptions(rawValue: 0), animations: {
                self.dialogView.center = CGPoint(x: self.center.x, y: self.frame.height + self.dialogView.frame.height/2)
            }, completion: { (completed) in
                self.removeFromSuperview()
                completion?()
            })
        } else {
            experimentPicker.removeFromParentViewController()
            self.removeFromSuperview()
        }
    }
    
    func experimentSelected(_ experiment: Experiment) {
        guard let url = experiment.source else {
            return
        }
        dismiss(animated: true,  completion: {() in _ =
            self.delegate?.launchExperimentByURL(url)
        })
    }
    
}
