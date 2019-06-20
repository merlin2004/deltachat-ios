//
//  AppCoordinator.swift
//  deltachat-ios
//
//  Created by Jonas Reinsch on 07.11.17.
//  Copyright © 2017 Jonas Reinsch. All rights reserved.
//

import UIKit
import ALCameraViewController
import Photos
import MobileCoreServices


class AppCoordinator: NSObject, Coordinator, UITabBarControllerDelegate {
	private let window: UIWindow

	var rootViewController: UIViewController {
		return tabBarController
	}

	private var childCoordinators: [Coordinator] = []

	private lazy var tabBarController: UITabBarController = {
		let tabBarController = UITabBarController()
		tabBarController.viewControllers = [contactListController, mailboxController, profileController, chatListController, settingsController]
		// put viewControllers here
		tabBarController.delegate = self
		tabBarController.tabBar.tintColor = DCColors.primary
		// tabBarController.tabBar.isTranslucent = false
		return tabBarController
	}()

	// MARK: viewControllers

	private lazy var contactListController: UIViewController = {
		let controller = ContactListController()
		let nav = DCNavigationController(rootViewController: controller)
		let settingsImage = UIImage(named: "contacts")
		nav.tabBarItem = UITabBarItem(title: "Contacts", image: settingsImage, tag: 4)
		let coordinator = ContactListCoordinator(navigationController: nav)
		self.childCoordinators.append(coordinator)
		controller.coordinator = coordinator
		return nav
	}()

	private lazy var mailboxController: UIViewController = {
		let controller = MailboxViewController(chatId: Int(DC_CHAT_ID_DEADDROP), title: "Mailbox")
		controller.disableWriting = true
		let nav = DCNavigationController(rootViewController: controller)
		let settingsImage = UIImage(named: "message")
		nav.tabBarItem = UITabBarItem(title: "Mailbox", image: settingsImage, tag: 0)
		let coordinator = MailboxCoordinator(navigationController: nav)
		self.childCoordinators.append(coordinator)
		controller.coordinator = coordinator
		return nav
	}()

	private lazy var profileController: UIViewController = {
		let controller = ProfileViewController()
		let nav = DCNavigationController(rootViewController: controller)
		let settingsImage = UIImage(named: "report_card")
		nav.tabBarItem = UITabBarItem(title: "My Profile", image: settingsImage, tag: 1)
		let coordinator = ProfileCoordinator(rootViewController: nav)
		self.childCoordinators.append(coordinator)
		controller.coordinator = coordinator
		return nav
	}()

	private lazy var chatListController: UIViewController = {
		let controller = ChatListController()
		let nav = DCNavigationController(rootViewController: controller)
		let settingsImage = UIImage(named: "chat")
		nav.tabBarItem = UITabBarItem(title: "Chats", image: settingsImage, tag: 2)
		let coordinator = ChatListCoordinator(navigationController: nav)
		self.childCoordinators.append(coordinator)
		controller.coordinator = coordinator
		return nav
	}()

	private lazy var settingsController: UIViewController = {
		let controller = SettingsViewController()
		let nav = DCNavigationController(rootViewController: controller)
		let settingsImage = UIImage(named: "settings")
		nav.tabBarItem = UITabBarItem(title: "Settings", image: settingsImage, tag: 3)
		let coordinator = SettingsCoordinator(navigationController: nav)
		self.childCoordinators.append(coordinator)
		controller.coordinator = coordinator
		return nav
	}()

	init(window: UIWindow) {
		self.window = window
		super.init()
		window.rootViewController = rootViewController
		window.makeKeyAndVisible()
	}

	public func start() {
	print(tabBarController.selectedIndex)
		showTab(index: 3)
	}

	func showTab(index: Int) {
		tabBarController.selectedIndex = index
	}

	func presentLoginController() {
		let accountSetupController = AccountSetupController()
		let accountSetupNavigationController = DCNavigationController(rootViewController: accountSetupController)
		rootViewController.present(accountSetupNavigationController, animated: false, completion: nil)
	}
}

extension AppCoordinator: UITabBarDelegate {
	func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
		print("item selected")
	}

	func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
		print("shouldSelect")
		return true 
	}
}

class ContactListCoordinator: Coordinator {
	let navigationController: UINavigationController

	var childCoordinators: [Coordinator] = []

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}

	func showContactDetail(contactId: Int) {
		let contactDetailController = ContactDetailViewController(contactId: contactId)
		contactDetailController.showChatCell = true
		let coordinator = ContactDetailCoordinator(navigationController: navigationController)
		childCoordinators.append(coordinator)
		contactDetailController.coordinator = coordinator
		navigationController.pushViewController(contactDetailController, animated: true)
	}

	func showChat(chatId: Int) {
		let chatVC = ChatViewController(chatId: chatId)
		let coordinator = ChatViewCoordinator(navigationController: navigationController, chatId: chatId)
		childCoordinators.append(coordinator)
		chatVC.coordinator = coordinator
		navigationController.pushViewController(chatVC, animated: true)
	}
}

// since mailbox and chatView -tab both use ChatViewController we want to be able to assign different functionality via coordinators -> therefore we override unneeded functions such as showChatDetail -> maybe find better solution in longterm
class MailboxCoordinator: ChatViewCoordinator {

	init(navigationController: UINavigationController) {
		super.init(navigationController: navigationController, chatId: -1)
	}

	override func showChatDetail(chatId _: Int) {
		// ignore for now
	}

	override func showCameraViewController() {
		// ignore
	}
}

class ProfileCoordinator: Coordinator {
	var rootViewController: UIViewController

	init(rootViewController: UIViewController) {
		self.rootViewController = rootViewController
	}
}

class ChatListCoordinator: Coordinator {
	let navigationController: UINavigationController

	var childCoordinators: [Coordinator] = []

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}

	func showNewChatController() {
		let newChatVC = NewChatViewController()
		let coordinator = NewChatCoordinator(navigationController: navigationController)
		childCoordinators.append(coordinator)
		newChatVC.coordinator = coordinator
		navigationController.pushViewController(newChatVC, animated: true)
	}

	func showChat(chatId: Int) {
		let chatVC = ChatViewController(chatId: chatId)
		let coordinator = ChatViewCoordinator(navigationController: navigationController, chatId: chatId)
		childCoordinators.append(coordinator)
		chatVC.coordinator = coordinator
		navigationController.pushViewController(chatVC, animated: true)
	}
}

class SettingsCoordinator: Coordinator {
	let navigationController: UINavigationController

	var childCoordinators:[Coordinator] = []

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}

	func showAccountSetupController() {
		let accountSetupVC = AccountSetupController()
		let coordinator = AccountSetupCoordinator(navigationController: navigationController)
		childCoordinators.append(coordinator)
		accountSetupVC.coordinator = coordinator
		navigationController.pushViewController(accountSetupVC, animated: true)
	}

	func showEditSettingsController(option: SettingsEditOption) {
		let editController = EditSettingsController()
		editController.activateField(option: option)
		navigationController.pushViewController(editController, animated: true)
	}

	func showLoginController() {
		let accountSetupVC = AccountSetupController()
		let coordinator = AccountSetupCoordinator(navigationController: navigationController)
		childCoordinators.append(coordinator)
		accountSetupVC.coordinator = coordinator
		let accountSetupNavigationController = DCNavigationController(rootViewController: accountSetupVC)
		navigationController.present(accountSetupNavigationController, animated: true, completion: nil)
	}
}

class AccountSetupCoordinator: Coordinator {
	let navigationController: UINavigationController

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}

	func showImapPortOptions() {
		let currentMailPort = MRConfig.mailPort ?? MRConfig.configuredMailPort
		let currentPort = Int(currentMailPort)
		let portSettingsController = PortSettingsController(sectionTitle: "IMAP Port", ports: [143, 993], currentPort: currentPort)
		portSettingsController.onDismiss = {
			port in
			MRConfig.mailPort = port
			dc_configure(mailboxPointer)
		}
		navigationController.pushViewController(portSettingsController, animated: true)
	}

	func showImapSecurityOptions() {
		let currentSecurityOption = MRConfig.getImapSecurity()
		let convertedOption = SecurityConverter.convertHexToString(type: .IMAPSecurity, hex: currentSecurityOption)
		let securitySettingsController = SecuritySettingsController(title: "IMAP Security", options: ["Automatic", "SSL / TLS", "STARTTLS", "OFF"], selectedOption: convertedOption)
		securitySettingsController.onDismiss = {
			option in
			if let secValue = SecurityValue(rawValue: option) {
				let value = SecurityConverter.convertValueToInt(type: .IMAPSecurity, value: secValue)
				MRConfig.setImapSecurity(imapFlags: value)
				dc_configure(mailboxPointer)
			}
		}
		navigationController.pushViewController(securitySettingsController, animated: true)
	}

	func showSmtpPortsOptions() {
		let currentMailPort = MRConfig.sendPort ?? MRConfig.configuredSendPort
		let currentPort = Int(currentMailPort)
		let portSettingsController = PortSettingsController(sectionTitle: "SMTP Port", ports: [25, 465, 587], currentPort: currentPort)
		portSettingsController.onDismiss = {
			port in
			MRConfig.sendPort = port
			dc_configure(mailboxPointer)
		}
		navigationController.pushViewController(portSettingsController, animated: true)
	}

	func showSmptpSecurityOptions() {
		let currentSecurityOption = MRConfig.getSmtpSecurity()
		let convertedOption = SecurityConverter.convertHexToString(type: .SMTPSecurity, hex: currentSecurityOption)
		let securitySettingsController = SecuritySettingsController(title: "IMAP Security", options: ["Automatic", "SSL / TLS", "STARTTLS", "OFF"], selectedOption: convertedOption)
		securitySettingsController.onDismiss = {
			option in
			if let secValue = SecurityValue(rawValue: option) {
				let value = SecurityConverter.convertValueToInt(type: .SMTPSecurity, value: secValue)
				MRConfig.setSmtpSecurity(smptpFlags: value)
				dc_configure(mailboxPointer)
			}
		}
		navigationController.pushViewController(securitySettingsController, animated: true)
	}
}

class NewChatCoordinator: Coordinator {
	let navigationController: UINavigationController

	private var childCoordinators: [Coordinator] = []

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}

	func showNewGroupController() {
		let newGroupController = NewGroupViewController()
		let coordinator = NewGroupCoordinator(navigationController: navigationController)
		childCoordinators.append(coordinator)
		newGroupController.coordinator = coordinator
		navigationController.pushViewController(newGroupController, animated: true)
	}

	func showQRCodeController() {
		let controller = QrCodeReaderController()
		// controller.delegate = self
		// present(controller, animated: true, completion: nil)
	}

	func showNewContactController() {
		let newContactController = NewContactController()
		let coordinator = EditContactCoordinator(navigationController: navigationController)
		childCoordinators.append(coordinator)
		newContactController.coordinator = coordinator
		navigationController.pushViewController(newContactController, animated: true)
	}

	func showNewChat(contactId: Int) {
		let chatId = dc_create_chat_by_contact_id(mailboxPointer, UInt32(contactId))
		showChat(chatId: Int(chatId))
	}

	func showChat(chatId: Int) {
		let chatViewController = ChatViewController(chatId: chatId)
		let coordinator = ChatViewCoordinator(navigationController: navigationController, chatId: chatId)
		childCoordinators.append(coordinator)
		chatViewController.coordinator = coordinator
		navigationController.pushViewController(chatViewController, animated: true)
		navigationController.viewControllers.remove(at: 1)
	}
}

class GroupChatDetailCoordinator: Coordinator {
	let navigationController: UINavigationController

	private var childCoordinators: [Coordinator] = []

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}

	func showSingleChatEdit(contactId: Int) {
		let editContactController = EditContactController(contactIdForUpdate: contactId)
		let coordinator = EditContactCoordinator(navigationController: navigationController)
		childCoordinators.append(coordinator)
		editContactController.coordinator = coordinator
		navigationController.pushViewController(editContactController, animated: true)
	}

	func showAddGroupMember(chatId: Int) {
		let groupMemberViewController = AddGroupMembersViewController(chatId: chatId)
		navigationController.pushViewController(groupMemberViewController, animated: true)
	}

	func showGroupChatEdit(chat: MRChat) {
		let editGroupViewController = EditGroupViewController(chat: chat)
		let coordinator = EditGroupCoordinator(navigationController: navigationController)
		childCoordinators.append(coordinator)
		editGroupViewController.coordinator = coordinator
		navigationController.pushViewController(editGroupViewController, animated: true)
	}
}

class ChatViewCoordinator: NSObject, Coordinator {
	let navigationController: UINavigationController
	let chatId: Int
	var chatViewController: ChatViewController!

	var childCoordinators: [Coordinator] = []

	init(navigationController: UINavigationController, chatId: Int) {
		self.navigationController = navigationController
		self.chatId = chatId
	}

	func showChatDetail(chatId: Int) {
		let chat = MRChat(id: chatId)
		switch chat.chatType {
		case .SINGLE:
			if let contactId = chat.contactIds.first {
				let contactDetailController = ContactDetailViewController(contactId: contactId)
				let coordinator = ContactDetailCoordinator(navigationController: navigationController)
				childCoordinators.append(coordinator)
				contactDetailController.coordinator = coordinator
				navigationController.pushViewController(contactDetailController, animated: true)
			}
		case .GROUP, .VERYFIEDGROUP:
			let groupChatDetailViewController = GroupChatDetailViewController(chatId: chatId) // inherits from ChatDetailViewController
			let coordinator = GroupChatDetailCoordinator(navigationController: navigationController)
			childCoordinators.append(coordinator)
			groupChatDetailViewController.coordinator = coordinator
			navigationController.pushViewController(groupChatDetailViewController, animated: true)
		}
	}

	func showContactDetail(of contactId: Int) {
		let contactDetailController = ContactDetailViewController(contactId: contactId)
		contactDetailController.showChatCell = true
		//let nav = UINavigationController(rootViewController: contactDetailController)
		let coordinator = ContactDetailCoordinator(navigationController: navigationController)
		childCoordinators.append(coordinator)
		contactDetailController.coordinator = coordinator
		navigationController.pushViewController(contactDetailController, animated: true)
		// navigationController.present(nav, animated: true, completion: nil)
	}

	func showCameraViewController() {
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			let cameraViewController = CameraViewController { [weak self] image, _ in
				self?.navigationController.dismiss(animated: true, completion: nil)

				DispatchQueue.global().async {
					if let compressedImage = image?.dcCompress() {
						// at this point image is compressed by 85% by default
						let pixelSize = compressedImage.imageSizeInPixel()
						let width = Int32(exactly: pixelSize.width)!
						let height =  Int32(exactly: pixelSize.height)!
						let path = Utils.saveImage(image: compressedImage)
						let msg = dc_msg_new(mailboxPointer, DC_MSG_IMAGE)
						dc_msg_set_file(msg, path, "image/jpeg")
						dc_msg_set_dimension(msg, width, height)
						dc_send_msg(mailboxPointer, UInt32(self!.chatId), msg)
						// cleanup
						dc_msg_unref(msg)
					}
				}
			}

			navigationController.present(cameraViewController, animated: true, completion: nil)
		} else {
			let alert = UIAlertController(title: "Camera is not available", message: nil, preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
				self.navigationController.dismiss(animated: true, completion: nil)
			}))
			navigationController.present(alert, animated: true, completion: nil)
		}

	}
	func showVideoLibrary() {
		if PHPhotoLibrary.authorizationStatus() != .authorized {
			PHPhotoLibrary.requestAuthorization{status in
				DispatchQueue.main.async() { [weak self] in
					switch status {
					case  .denied,.notDetermined,.restricted:
						print("denied")
					case .authorized:
						self?.presentVideoLibrary()
					}
				}
			}
		} else {
			presentVideoLibrary()
		}
	}

	private func presentVideoLibrary() {
		if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
			let videoPicker = UIImagePickerController()
			videoPicker.title = "Videos"
			videoPicker.delegate = self
			videoPicker.sourceType = .photoLibrary
			videoPicker.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String]
			navigationController.present(videoPicker, animated: true, completion: nil)
		}
	}
}

extension ChatViewCoordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL{
			print("videourl: ", videoUrl)
			//trying compression of video
			let data = NSData(contentsOf: videoUrl as URL)!
			print("File size before compression: \(Double(data.length / 1048576)) mb")
			let size = Double(data.length / 1048576)
			print(size)
			let msg = dc_msg_new(mailboxPointer, DC_MSG_VIDEO)
			if let path = videoUrl.relativePath?.cString(using: .utf8) { //absoluteString?.cString(using: .utf8) {
				dc_msg_set_file(msg, path, nil)
				dc_send_msg(mailboxPointer, UInt32(chatId), msg)
				dc_msg_unref(msg)
			}
			// self.videoPickedBlock?(videoUrl, size)
		}
		else{
			print("Something went wrong in  video")
		}
		navigationController.dismiss(animated: true, completion: nil)
	}
}

class NewGroupCoordinator: Coordinator {
	let navigationController: UINavigationController

	private var childCoordinators: [Coordinator] = []

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}

	func showGroupNameController(contactIdsForGroup: Set<Int>) {
		let groupNameController = GroupNameController(contactIdsForGroup: contactIdsForGroup)
		let coordinator = GroupNameCoordinator(navigationController: navigationController)
		childCoordinators.append(coordinator)
		groupNameController.coordinator = coordinator
		navigationController.pushViewController(groupNameController, animated: true)
	}
}



class GroupNameCoordinator: Coordinator {
	let navigationController: UINavigationController

	private var childCoordinators: [Coordinator] = []

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}

	func showGroupChat(chatId: Int) {
		let chatViewController = ChatViewController(chatId: chatId)
		let coordinator = ChatViewCoordinator(navigationController: navigationController, chatId: chatId)
		childCoordinators.append(coordinator)
		chatViewController.coordinator = coordinator
		navigationController.popToRootViewController(animated: false)
		navigationController.pushViewController(chatViewController, animated: true)
	}
}

class ContactDetailCoordinator: Coordinator, ContactDetailCoordinatorProtocol {
	let navigationController: UINavigationController

	private var childCoordinators: [Coordinator] = []

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}

	func showChat(chatId: Int) {
		let chatViewController = ChatViewController(chatId: chatId)
		let coordinator = ChatViewCoordinator(navigationController: navigationController, chatId: chatId)
		childCoordinators.append(coordinator)
		chatViewController.coordinator = coordinator
		navigationController.popToRootViewController(animated: false)
		navigationController.pushViewController(chatViewController, animated: true)
	}

	func showEditContact(contactId: Int) {
		let editContactController = EditContactController(contactIdForUpdate: contactId)
		let coordinator = EditContactCoordinator(navigationController: navigationController)
		childCoordinators.append(coordinator)
		editContactController.coordinator = coordinator
		navigationController.pushViewController(editContactController, animated: true)
	}
}

class EditGroupCoordinator: Coordinator {
	let navigationController: UINavigationController

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}

	func navigateBack() {
		navigationController.popViewController(animated: true)
	}
}

class EditContactCoordinator: Coordinator, EditContactCoordinatorProtocol {

	let navigationController: UINavigationController

	var childCoordinators: [Coordinator] = []

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}

	func navigateBack() {
		navigationController.popViewController(animated: true)
	}

	func showChat(chatId: Int) {
		let chatViewController = ChatViewController(chatId: chatId)
		let coordinator = ChatViewCoordinator(navigationController: navigationController, chatId: chatId)
		coordinator.chatViewController = chatViewController
		childCoordinators.append(coordinator)
		chatViewController.coordinator = coordinator
		navigationController.popToRootViewController(animated: false)
		navigationController.pushViewController(chatViewController, animated: true)
	}
}

protocol ContactDetailCoordinatorProtocol: class {
	func showEditContact(contactId: Int)
	func showChat(chatId: Int)
}

protocol EditContactCoordinatorProtocol: class {
	func navigateBack()
	func showChat(chatId: Int)
}
