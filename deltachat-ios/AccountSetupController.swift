//
//  AccountSetupController.swift
//  deltachat-ios
//
//  Created by Bastian van de Wetering on 02.04.19.
//  Copyright © 2019 Jonas Reinsch. All rights reserved.
//

import SafariServices
import UIKit

class AccountSetupController: UITableViewController {
  private var backupProgressObserver: Any?
  private var configureProgressObserver: Any?
  private var oauth2Observer: Any?

  private lazy var hudHandler: HudHandler = {
    let hudHandler = HudHandler(parentView: self.tableView)
    return hudHandler
  }()

  private lazy var emailCell: TextFieldCell = {
    let cell = TextFieldCell.makeEmailCell(delegate: self)
    cell.textField.tag = 0
    cell.textField.accessibilityIdentifier = "emailTextField" // will be used to eventually show oAuth-Dialogue when pressing return key
    cell.setText(text: MRConfig.addr ?? nil)
    return cell
  }()

  private lazy var passwordCell: TextFieldCell = {
    let cell = TextFieldCell.makePasswordCell(delegate: self)
    cell.textField.tag = 1
    cell.accessibilityIdentifier = "passwordCell" // will be used to eventually show oAuth-Dialogue when selecting
    cell.setText(text: MRConfig.mailPw ?? nil)
    return cell
  }()

  /*
   Advanced Cells:
   IMAP Server, IMAP User, IMAP Port, IMAP Security, SMTP Server, SMTP User, SMTP Port, SMTP Password, SMTP Security
   */
  /*
   lazy var imapServerCell = TextFieldCell(description: "IMAP Server", placeholder: MRConfig.mailServer ?? MRConfig.configuredMailServer)
   lazy var imapUserCell = TextFieldCell(description: "IMAP User", placeholder: MRConfig.mailUser ?? MRConfig.configuredMailUser)
   lazy var imapPortCell = TextFieldCell(description: "IMAP Port", placeholder: MRConfig.mailPort ?? MRConfig.configuredMailPort)
   lazy var imapSecurityCell = TextFieldCell(description: "IMAP Security", placeholder: "to do")

   lazy var smtpServerCell = TextFieldCell(description: "SMTP Server", placeholder: MRConfig.sendServer ?? MRConfig.configuredSendServer)
   lazy var smtpUserCell = TextFieldCell(description: "SMTP User", placeholder: MRConfig.sendUser ?? MRConfig.configuredSendUser)
   lazy var smtpPortCell = TextFieldCell(description: "SMTP Port", placeholder: MRConfig.sendPort ?? MRConfig.configuredSendPort)
   lazy var smtpPasswordCell = TextFieldCell(description: "SMTP Password", placeholder: "*************")
   lazy var smtpSecurityCell = TextFieldCell(description: "SMTP Security", placeholder: "to do")
   */

  // TODO: consider adding delegates and tags by loop - leave for now like this
  lazy var imapServerCell: TextFieldCell = {
    let cell = TextFieldCell(description: "IMAP Server", placeholder: MRConfig.mailServer ?? MRConfig.configuredMailServer, delegate: self)
    cell.accessibilityIdentifier = "IMAPServerCell"
    cell.textField.tag = 2
    return cell
  }()

  lazy var imapUserCell: TextFieldCell = {
    let cell = TextFieldCell(description: "IMAP User", placeholder: MRConfig.mailUser ?? MRConfig.configuredMailUser, delegate: self)
    cell.accessibilityIdentifier = "IMAPUserCell"
    cell.textField.tag = 3
    return cell
  }()

  lazy var imapPortCell: TextFieldCell = {
    let cell = TextFieldCell(description: "IMAP Port", placeholder: MRConfig.mailPort ?? MRConfig.configuredMailPort, delegate: self)
    cell.accessibilityIdentifier = "IMAPPortCell"
    cell.textField.tag = 4
    return cell
  }()

  lazy var imapSecurityCell: TextFieldCell = {
    let text = "\(MRConfig.getImapSecurity())"
    let cell = TextFieldCell(description: "IMAP Security", placeholder: text, delegate: self)
    cell.accessibilityIdentifier = "IMAPSecurityCell"
    cell.textField.tag = 5
    cell.textField.keyboardType = UIKeyboardType.numberPad
    return cell
  }()

  lazy var smtpServerCell: TextFieldCell = {
    let cell = TextFieldCell(description: "SMTP Server", placeholder: MRConfig.sendServer ?? MRConfig.configuredSendServer, delegate: self)
    cell.accessibilityIdentifier = "SMTPServerCell"
    cell.textField.tag = 6
    return cell
  }()

  lazy var smtpUserCell: TextFieldCell = {
    let cell = TextFieldCell(description: "SMTP User", placeholder: MRConfig.sendUser ?? MRConfig.configuredSendUser, delegate: self)
    cell.accessibilityIdentifier = "SMTPUserCell"
    cell.textField.tag = 7
    return cell
  }()

  lazy var smtpPortCell: TextFieldCell = {
    let cell = TextFieldCell(description: "SMTP Port", placeholder: MRConfig.sendPort ?? MRConfig.configuredSendPort, delegate: self)
    cell.accessibilityIdentifier = "SMTPPortCell"
    cell.textField.tag = 8
    return cell
  }()

  lazy var smtpPasswordCell: TextFieldCell = {
    let cell = TextFieldCell(description: "SMTP Password", placeholder: "*************", delegate: self)
    cell.accessibilityIdentifier = "SMTPPasswordCell"
    cell.textField.tag = 9
    return cell
  }()

  lazy var smtpSecurityCell: TextFieldCell = {
    let text = "\(MRConfig.getSmtpSecurity())"
    let cell = TextFieldCell(description: "SMTP Security", placeholder: text, delegate: self)
    cell.accessibilityIdentifier = "SMTPSecurityCell"
    cell.textField.tag = 10
    cell.textField.keyboardType = UIKeyboardType.numberPad
    return cell
  }()

  // this loginButton can be enabled and disabled
  let loginButton: UIBarButtonItem = UIBarButtonItem(title: "Login", style: .done, target: self, action: #selector(loginButtonPressed))

  private lazy var basicSectionCells: [UITableViewCell] = [emailCell, passwordCell]
  private lazy var advancedSectionCells: [UITableViewCell] = [
    imapServerCell,
    imapUserCell,
    imapPortCell,
    imapSecurityCell,
    smtpServerCell,
    smtpUserCell,
    smtpPortCell,
    smtpPasswordCell,
    smtpSecurityCell,
  ]

  private var advancedSectionShowing: Bool = false

  init() {
    super.init(style: .grouped)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Login to your server"
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeButtonPressed))
    navigationItem.rightBarButtonItem = loginButton
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    addProgressHudEventListener()
    // loginButton.isEnabled = false
    print(emailCell.getText())
    print("account setup appeared")
  }

  override func viewDidDisappear(_: Bool) {
    let nc = NotificationCenter.default
    if let backupProgressObserver = self.backupProgressObserver {
      nc.removeObserver(backupProgressObserver)
    }
    if let configureProgressObserver = self.configureProgressObserver {
      nc.removeObserver(configureProgressObserver)
    }
    if let oauth2Observer = self.oauth2Observer {
      nc.removeObserver(oauth2Observer)
    }
  }

  // MARK: - Table view data source

  override func numberOfSections(in _: UITableView) -> Int {
    // #warning Incomplete implementation, return the number of sections
    return 2
  }

  override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
    // #warning Incomplete implementation, return the number of rows
    if section == 0 {
      return basicSectionCells.count
    } else {
      return advancedSectionShowing ? advancedSectionCells.count : 0
    }
  }

  override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 1 {
      return "Advanced"
    } else {
      return nil
    }
  }

  override func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if section == 1 {
      // Advanced Header
      let advancedView = AdvancedSectionHeader()
      advancedView.handleTap = toggleAdvancedSection
      // set tapHandler
      return advancedView

    } else {
      return nil
    }
  }

  override func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
    return 36.0
  }

  override func tableView(_: UITableView, titleForFooterInSection section: Int) -> String? {
    if section == 0 {
      return "There are no Delta Chat servers, your data stays on your device!"
    } else {
      return "For known email providers additional settings are setup automatically. Sometimes IMAP needs to be enabled in the web frontend. Consult your email provider or friends for help"
    }
  }

  override func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let section = indexPath.section
    let row = indexPath.row

    if section == 0 {
      // basicSection
      return basicSectionCells[row]
    } else {
      // advancedSection
      return advancedSectionCells[row]
    }
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // handle tap on password -> show eventuall oAuthDialogue
    if let cell = tableView.cellForRow(at: indexPath) as? TextFieldCell {
      if cell.accessibilityIdentifier == "passwordCell" {
        if let emailAdress = cell.getText() {
          _ = showOAuthAlertIfNeeded(emailAddress: emailAdress, handleCancel: nil)
        }
      }
    }
  }

  private func toggleAdvancedSection(button: UILabel) {
    let willShow = !advancedSectionShowing

    // extract indexPaths from advancedCells
    let advancedIndexPaths: [IndexPath] = advancedSectionCells.indices.map { IndexPath(row: $0, section: 1) }

    // advancedSectionCells.indices.map({indexPaths.append(IndexPath(row: $0, section: 1))}

    // set flag before delete/insert operation, because cellForRowAt will be triggered and uses this flag
    advancedSectionShowing = willShow

    button.text = willShow ? "Hide" : "Show"

    if willShow {
      tableView.insertRows(at: advancedIndexPaths, with: .fade)
    } else {
      tableView.deleteRows(at: advancedIndexPaths, with: .fade)
    }
  }

  @objc private func loginButtonPressed() {
    guard let emailAddress = emailCell.getText() else {
      return // handle case when either email or pw fields are empty
    }

    let oAuthStarted = showOAuthAlertIfNeeded(emailAddress: emailAddress, handleCancel: loginButtonPressed) // if canceled we will run this method again but this time oAuthStarted will be false

    if oAuthStarted {
      // the loginFlow will be handled by oAuth2
      return
    }

    let password = passwordCell.getText() ?? "" // empty passwords are ok -> for oauth there is no password needed
    login(emailAddress: emailAddress, password: password)
  }

  private func login(emailAddress: String, password: String, skipAdvanceSetup: Bool = false) {
    MRConfig.addr = emailAddress
    MRConfig.mailPw = password
    if skipAdvanceSetup {
      evaluluateAdvancedSetup() // this will set MRConfig related to advanced fields
    }
    dc_configure(mailboxPointer)
    hudHandler.showBackupHud("Configuring account")
  }

  @objc func closeButtonPressed() {
    dismiss(animated: true, completion: nil)
  }

  // returns true if needed
  private func showOAuthAlertIfNeeded(emailAddress: String, handleCancel: (() -> Void)?) -> Bool {
    if MRConfig.getAuthFlags() == 4 {
      // user has previously denied oAuth2-setup
      return false
    }

    guard let oAuth2UrlPointer = dc_get_oauth2_url(mailboxPointer, emailAddress, "chat.delta:/auth") else {
      return false
    }

    let oAuth2Url = String(cString: oAuth2UrlPointer)

    if let url = URL(string: oAuth2Url) {
      let title = "Continue with simplified setup"
      // swiftlint:disable all
      let message = "The entered e-mail address supports a simplified setup (oAuth2).\n\nIn the next step, please allow Delta Chat to act as your Chat with E-Mail app.\n\nThere are no Delta Chat servers, your data stays on your device."

      let oAuthAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      let confirm = UIAlertAction(title: "Confirm", style: .default, handler: {
        [unowned self] _ in
        let nc = NotificationCenter.default
        self.oauth2Observer = nc.addObserver(self, selector: #selector(self.oauthLoginApproved), name: NSNotification.Name("oauthLoginApproved"), object: nil)
        self.launchOAuthBrowserWindow(url: url)
      })
      let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: {
        _ in
        MRConfig.setAuthFlags(flags: Int(DC_LP_AUTH_NORMAL))
        handleCancel?()
      })
      oAuthAlertController.addAction(confirm)
      oAuthAlertController.addAction(cancel)

      present(oAuthAlertController, animated: true, completion: nil)
      return true
    } else {
      return false
    }
  }

  @objc func oauthLoginApproved(notification: Notification) {
    guard let userInfo = notification.userInfo, let token = userInfo["token"] as? String, let emailAddress = emailCell.getText() else {
      return
    }
    passwordCell.setText(text: token)
    MRConfig.setAuthFlags(flags: Int(DC_LP_AUTH_OAUTH2))
    login(emailAddress: emailAddress, password: token, skipAdvanceSetup: true)
  }

  private func launchOAuthBrowserWindow(url: URL) {
    UIApplication.shared.open(url) // this opens safari as seperate app
  }

  private func addProgressHudEventListener() {
    let nc = NotificationCenter.default
    backupProgressObserver = nc.addObserver(
      forName: dcNotificationBackupProgress,
      object: nil,
      queue: nil
    ) {
      notification in
      if let ui = notification.userInfo {
        if ui["error"] as! Bool {
          self.hudHandler.setHudError(ui["errorMessage"] as? String)
        } else if ui["done"] as! Bool {
          self.hudHandler.setHudDone(callback: self.handleLoginSuccess)
        } else {
          self.hudHandler.setHudProgress(ui["progress"] as! Int)
        }
      }
    }
    configureProgressObserver = nc.addObserver(
      forName: dcNotificationConfigureProgress,
      object: nil,
      queue: nil
    ) {
      notification in
      if let ui = notification.userInfo {
        if ui["error"] as! Bool {
          self.hudHandler.setHudError(ui["errorMessage"] as? String)
        } else if ui["done"] as! Bool {
          self.hudHandler.setHudDone(callback: self.handleLoginSuccess)
        } else {
          self.hudHandler.setHudProgress(ui["progress"] as! Int)
        }
      }
    }
  }

  private func evaluluateAdvancedSetup() {
    for cell in advancedSectionCells {
      if let textFieldCell = cell as? TextFieldCell {
        switch cell.accessibilityIdentifier {
        case "IMAPServerCell":
          MRConfig.mailServer = textFieldCell.getText() ?? nil
        case "IMAPUserCell":
          MRConfig.mailUser = textFieldCell.getText() ?? nil
        case "IMAPPortCell":
          MRConfig.mailPort = textFieldCell.getText() ?? nil
        case "IMAPSecurityCell":
          let flag = 0
          MRConfig.setImapSecurity(imapFlags: flag)
        case "SMTPServerCell":
          MRConfig.sendServer = textFieldCell.getText() ?? nil
        case "SMTPSUserCell":
          MRConfig.sendUser = textFieldCell.getText() ?? nil
        case "SMTPPortCell":
          MRConfig.sendPort = textFieldCell.getText() ?? nil
        case "SMTPPasswordCell":
          MRConfig.sendPw = textFieldCell.getText() ?? nil
        case "SMTPSecurityCell":
          let flag = 0
          MRConfig.setSmtpSecurity(smptpFlags: flag)
        default:
          logger.info("unknown identifier", cell.accessibilityIdentifier ?? "")
        }
      }
    }
  }

  private func handleLoginSuccess() {
    // used when login hud successfully went trough
    dismiss(animated: true, completion: nil)
  }
}

extension AccountSetupController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    let currentTag = textField.tag

    if textField.accessibilityIdentifier == "emailTextField", showOAuthAlertIfNeeded(emailAddress: textField.text ?? "", handleCancel: {
      // special case: email field should check for potential oAuth

      // this will activate passwordTextField if oAuth-Dialogue was canceled
      passwordCell.textField.becomeFirstResponder()
    }) {
      // all the action is defined in if condition
    } else {
      if let nextField = tableView.viewWithTag(currentTag + 1) as? UITextField {
        if nextField.tag > 1, !advancedSectionShowing {
          // gets here when trying to activate a collapsed cell
          return false
        }
        nextField.becomeFirstResponder()
      }
    }

    return false
  }
}

class AdvancedSectionHeader: UIView {
  var handleTap: ((UILabel) -> Void)?

  private var label: UILabel = {
    let label = UILabel()
    label.text = "ADVANCED"
    label.font = UIFont.systemFont(ofSize: 15)
    label.textColor = UIColor.darkGray
    return label
  }()

  /*
   why UILabel, why no UIButton? For unknown reasons UIButton's target function was not triggered when one of the textfields in the tableview was active -> used label as workaround
   */
  private lazy var toggleButton: UILabel = {
    let label = UILabel()
    label.text = "Show"
    label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
    label.textColor = UIColor.systemBlue
    return label
  }()

//
  //	private var toggleButton:UIButton = {
  //		let button = UIButton(type: .system)
  //		button.setTitle("Show", for: .normal)
  //		button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside )
  //		//button.target(forAction: #selector(buttonTapped(_:)), withSender: self)
  //		return button
  //	}()

  init() {
    super.init(frame: .zero) // will be constraint from tableViewDelegate
    setupSubviews()
    let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped)) // use this if the whole header is supposed to be clickable
    addGestureRecognizer(tap)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupSubviews() {
    addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15).isActive = true
    label.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
    addSubview(toggleButton)
    toggleButton.translatesAutoresizingMaskIntoConstraints = false

    toggleButton.leadingAnchor.constraint(equalTo: trailingAnchor, constant: -60).isActive = true // since button will change title it should be left aligned
    toggleButton.centerYAnchor.constraint(equalTo: label.centerYAnchor, constant: 0).isActive = true
  }

  @objc func buttonTapped(_: UIButton) {
    // handleTap?(button)
  }

  @objc func viewTapped() {
    handleTap?(toggleButton)
  }
}

/*
 class InputTableViewCell: UITableViewCell {
 lazy var inputField: UITextField = {
 let textField = UITextField()
 return textField
 }()

 init() {
 super.init(style: .default, reuseIdentifier: nil)
 setupView()
 }

 required init?(coder aDecoder: NSCoder) {
 fatalError("init(coder:) has not been implemented")
 }

 private func setupView() {
 contentView.addSubview(inputField)
 inputField.translatesAutoresizingMaskIntoConstraints = false
 inputField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
 inputField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5).isActive = true
 inputField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
 inputField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 100).isActive = true
 inputField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0).isActive = true
 }
 public func getText() -> String? {
 return inputField.text
 }
 }

 class PasswordInputCell: UITableViewCell {
 lazy var inputField: UITextField = {
 let textField = UITextField()
 textField.isSecureTextEntry = true
 return textField
 }()

 // TODO: to add Eye-icon -> uncomment -> add to inputField.rightView
 /*
  lazy var makeVisibleIcon: UIImageView = {
  let view = UIImageView(image: )
  return view
  }()
  */
 init() {
 super.init(style: .default, reuseIdentifier: nil)
 setupView()
 }

 required init?(coder aDecoder: NSCoder) {
 fatalError("init(coder:) has not been implemented")
 }

 private func setupView() {
 contentView.addSubview(inputField)
 inputField.translatesAutoresizingMaskIntoConstraints = false
 inputField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
 inputField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5).isActive = true
 inputField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
 inputField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 100).isActive = true
 inputField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0).isActive = true
 }

 public func getText() -> String? {
 return inputField.text
 }
 }

 */
