//
//  VyncCell.swift
//  VYNC
//
//  Created by Thomas Abend on 1/21/15.
//  Copyright (c) 2015 Thomas Abend. All rights reserved.
//

import UIKit


class VyncCell: UITableViewCell, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var lengthLabel:UILabel!
    @IBOutlet weak var titleLabel:UILabel!
    @IBOutlet weak var statusLogo: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    
    var isMoving = false
    var isFlipped = false

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyle.None
        lengthLabel.layer.masksToBounds = true
        lengthLabel.layer.cornerRadius = 12.5
    }
    
    func selectCellAnimation() {
        if self.isMoving == false {
            self.isMoving = true
            UIView.animateWithDuration(0.33, delay:0, options: .CurveEaseIn, animations:{
                self.titleLabel.transform = CGAffineTransformMakeTranslation(0, -6)
                self.contentView.layoutIfNeeded()
                }, completion:
                { finished in
                    self.subTitle.textColor = UIColor.blackColor()
                    self.deselectCellAnimation()
                })
        }
    }
    
    func deselectCellAnimation() {
        UIView.animateWithDuration(0.5, delay:2.5, options: .CurveEaseIn, animations:{
            self.titleLabel.transform = CGAffineTransformMakeTranslation(0, 0)
            self.contentView.layoutIfNeeded()
            }, completion:
            { finished in
                self.subTitle.textColor = UIColor.clearColor()
                self.isMoving = false
            }
        )
    }
    
}
