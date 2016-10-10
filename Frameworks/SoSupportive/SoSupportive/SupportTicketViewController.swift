//
//  SupportTicketViewController.swift
//  Keytester
//
//  Created by Brandon Pluim on 6/14/16.
//  Copyright © 2016 Instructure Inc. All rights reserved.
//

import UIKit

import SoLazy
import Eureka
import SoPretty
import TooLegit

private enum SupportTicketCellTag: String {
    case Email, Subject, Impact, Comment
}

public class SupportTicketViewController : FormViewController {

    private var requesterName: String = "Unknown User"
    private var requesterUsername: String = "Unknown User Name"
    private var requesterEmail: String? = nil {
        didSet {
            if let row = form.rowByTag(SupportTicketCellTag.Email.rawValue) {
                row.evaluateHidden()
            }
        }
    }
    private var baseURL : NSURL? = nil
    private var type: SupportTicketType = .Problem
    private var session: Session? = nil

    private var cancelButton: UIBarButtonItem!
    private var doneButton: UIBarButtonItem!
    private let notification = ToastManager()
    private var sendTask: NSURLSessionDataTask?

    public static func new(session: Session, type: SupportTicketType) -> SupportTicketViewController{
        let controller = SupportTicketViewController()
        controller.requesterName = session.user.sortableName ?? session.user.name
        controller.requesterEmail = session.user.email
        controller.requesterUsername = session.user.name
        controller.baseURL = session.baseURL
        controller.type = type
        controller.session = session

        return controller
    }

    // ---------------------------------------------
    // MARK: - UIViewController LifeCycle
    // ---------------------------------------------
    public override func viewDidLoad() {
        super.viewDidLoad()

        cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(SupportTicketViewController.cancelTapped(_:)))
        doneButton = UIBarButtonItem(title: "Send", style: .Plain, target: self, action: #selector(SupportTicketViewController.doneTapped(_:)))

        self.navigationItem.leftBarButtonItem = cancelButton
        self.navigationItem.rightBarButtonItem = doneButton

        form +++ Section()
            <<< PushRow<String>() {
                $0.title = NSLocalizedString("Impact:", comment: "Impact Title")
                $0.selectorTitle = NSLocalizedString("Select Impact", comment: "Select Impact Placeholder")
                $0.options = ImpactLevel.impacts().map { $0.description() }
                $0.value = ImpactLevel.None.description()
                $0.tag = SupportTicketCellTag.Impact.rawValue
                }.onChange { [weak self] row in
                    self?.validateForm()
            }
            <<< EmailRow(SupportTicketCellTag.Email.rawValue) { [weak self] in
                let rowHidden = (self?.requesterEmail != nil)
                $0.hidden = Condition(booleanLiteral: rowHidden)
                }.cellSetup { cell, row in
                cell.textField.placeholder = "Your Email"
                }.onChange { [weak self] row in
                    self?.validateForm()
            }
            <<<  TextRow(SupportTicketCellTag.Subject.rawValue).cellSetup { cell, row in
                cell.textField.placeholder = row.tag
                }.onChange { [weak self] row in
                    self?.validateForm()
            }
            <<< TextAreaRow(SupportTicketCellTag.Comment.rawValue) {
                $0.placeholder = type.description()
                $0.cell.textView.accessibilityHint = "\($0.placeholder)"
                $0.textAreaHeight = .Dynamic(initialTextViewHeight: 100)
                }.onChange { [weak self] row in
                    self?.validateForm()
            }

        validateForm()
    }

    // ---------------------------------------------
    // MARK: - IBActions
    // ---------------------------------------------
    func doneTapped(barButtonItem: UIBarButtonItem) {
        guard let impactRow = form.rowByTag(SupportTicketCellTag.Impact.rawValue) as? PushRow<String>,
            subjectRow = form.rowByTag(SupportTicketCellTag.Subject.rawValue) as? TextRow,
            commentRow = form.rowByTag(SupportTicketCellTag.Comment.rawValue) as? TextAreaRow,
            impactValue = impactRow.value,
            impact = ImpactLevel.impactFromDescription(impactValue),
            subject = subjectRow.value?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()),
            comment = commentRow.value?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) else {
                notification.statusBarToastSuccess(NSLocalizedString("Invalid Input.  Check fields and try again.", comment: "Support Ticket Invalid Input Message"))
                return
        }

        var email = requesterEmail ?? "unknown_email@unknown.com"
        if let emailRow = form.rowByTag(SupportTicketCellTag.Email.rawValue) as? TextRow,
        emailValue = emailRow.value?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) {
            email = requesterEmail ?? emailValue
        }

        let realBaseURL = baseURL ?? NSURL(string: "https://canvas.instructure.com")!
        let url = realBaseURL.URLByAppendingPathComponent("error_reports.json")
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let supportTicket: SupportTicket
        if let session = session {
            supportTicket = SupportTicket(session: session, subject: subject, body: comment, impact: impact, type: type)
        } else {
            supportTicket = SupportTicket(requesterName: requesterName, requesterUsername: requesterUsername, requesterEmail: email, requesterDomain: realBaseURL, subject: subject, body: comment, impact: impact, type: type)
        }
        let data = try! NSJSONSerialization.dataWithJSONObject(supportTicket.dictionaryValue(), options: .PrettyPrinted)
        request.HTTPBody = data

        setLoading(true)
        sendTask = NSURLSession.sharedSession().dataTaskWithRequest(request){ [weak self] data,response,error in
            let notification = ToastManager()
            guard error == nil else {
                if let _ = error {
                    dispatch_async(dispatch_get_main_queue()) {
                        self?.setLoading(false)
                        notification.statusBarToastSuccess(NSLocalizedString("Request Failed!  Check network and try again!", comment: "Support Ticket Creation Failed"))
                    }
                }
                return
            }

            dispatch_async(dispatch_get_main_queue()) {
                self?.setLoading(false)
                self?.navigationController?.popViewControllerAnimated(true)
                notification.statusBarToastSuccess(NSLocalizedString("Thanks, your request was received!", comment: "Support Ticket Created Successfully"))
            }
        }

        sendTask?.resume()
    }

    func cancelTapped(barButtonItem: UIBarButtonItem) {
        sendTask?.cancel()
        navigationController?.popViewControllerAnimated(true)
    }

    // ---------------------------------------------
    // MARK: - Validation
    // ---------------------------------------------
    func validateForm() {
        doneButton.enabled = isFormValid()
    }

    func setLoading(loading: Bool) {
        if loading {
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
            activityIndicator.startAnimating()
        } else {
            navigationItem.rightBarButtonItem = doneButton
        }
    }

    func isFormValid() -> Bool {
        if let emailRow = form.rowByTag(SupportTicketCellTag.Email.rawValue) as? EmailRow,
            formEmail = emailRow.value {
            requesterEmail = formEmail
        }

        guard let impactRow = form.rowByTag(SupportTicketCellTag.Impact.rawValue) as? PushRow<String>,
            subjectRow = form.rowByTag(SupportTicketCellTag.Subject.rawValue) as? TextRow,
            commentRow = form.rowByTag(SupportTicketCellTag.Comment.rawValue) as? TextAreaRow,
            impact = impactRow.value,
            email = requesterEmail,
            subject = subjectRow.value?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()),
            comment = commentRow.value?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) else {
                return false
        }

        return email.isValidEmail() && impact != ImpactLevel.None.description() && !subject.isEmpty && !comment.isEmpty
    }

}
