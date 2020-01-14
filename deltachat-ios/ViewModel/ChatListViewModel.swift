import UIKit

typealias VoidFunction = () -> Void

protocol ChatListViewModelProtocol: class, UISearchResultsUpdating {
    var showArchive: Bool { get }
    var onChatListUpdate: VoidFunction? { get set }
    var chatsCount: Int { get }
    var archivedChatsCount: Int { get }
    func chatIdFor(indexPath: IndexPath) -> Int?
    func msgIdFor(indexPath: IndexPath) -> Int?
    func chatSummaryFor(indexPath: IndexPath) -> DcLot
    func chatDetailFor(indexPath: IndexPath) -> ChatListCellViewModelProtocol
    func deleteChat(chatId: Int)
    func archieveChat(chatId: Int)
    func getUnreadMessages(chatId: Int) -> Int
    func beginFiltering()
    func endFiltering()
}

protocol ChatListCellViewModelProtocol {

}

class ChatListCellViewModel: ChatListCellViewModelProtocol {

}

class ChatListViewModel: NSObject, ChatListViewModelProtocol {

    func msgIdFor(indexPath: IndexPath) -> Int? {
        return chatList.getMsgId(index: indexPath.row)
    }

    func chatIdFor(indexPath: IndexPath) -> Int? {
        return chatList.getChatId(index: indexPath.row)
    }

    var archivedChatsCount: Int {
        let chatList = dcContext.getChatlist(flags: DC_GCL_ARCHIVED_ONLY, queryString: nil, queryId: 0)
        return chatList.length
    }

    var onChatListUpdate: VoidFunction?

    var chatsCount: Int {
        return chatList.length
    }

    private var chatList: DcChatlist {
        var gclFlags: Int32 = 0
        if showArchive {
            gclFlags |= DC_GCL_ARCHIVED_ONLY
        }
        return dcContext.getChatlist(flags: gclFlags, queryString: nil, queryId: 0)
    }

    private var unfilteredSearchResults: [SearchResult<DcChat>] = []
    private var filteredSearchResults: [SearchResult<DcChat>] = []
    private var searchResults: [SearchResult<DcChat>] = []

    private var dcContext: DcContext
    let showArchive: Bool

    init(dcContext: DcContext, showArchive: Bool) {
        self.dcContext = dcContext
        self.showArchive = showArchive
        dcContext.updateDeviceChats()
    }

    func chatDetailFor(indexPath: IndexPath) -> ChatListCellViewModelProtocol {
        return ChatListCellViewModel()
    }

    func chatSummaryFor(indexPath: IndexPath) -> DcLot{
        return chatList.getSummary(index: indexPath.row)
    }

    func deleteChat(chatId: Int) {
        dcContext.deleteChat(chatId: chatId)
        onChatListUpdate?()
    }

    func archieveChat(chatId: Int) {
        dcContext.archiveChat(chatId: chatId, archive: !self.showArchive)
        onChatListUpdate?()
    }

    func getUnreadMessages(chatId: Int) -> Int {
        let msg = dcContext.getUnreadMessages(chatId: chatId)
        return msg
    }

    func beginFiltering() {
        let chatList = self.chatList
        // do this once
        self.unfilteredSearchResults = (0..<chatsCount).map {
            let id = chatList.getChatId(index: $0)
            return SearchResult<DcChat>(entity: DcChat(id: id), indexesToHighlight: [])
        }
    }

    func endFiltering() {

    }


}

// MARK: UISearchResultUpdating
extension ChatListViewModel: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterContentForSearchText(searchText)
        }
    }

    private func filterContentForSearchText(_ searchText: String, scope _: String = String.localized("pref_show_emails_all")) {

        let filteredChats = dc_search_msgs(dcContext, 0, searchText)

        let chatsWithHighlight: [SearchResult<DcChat>] = unfilteredSearchResults.map {
            chat in
            let indexes = chat.entity.containsExact(searchText: searchText)
            return SearchResult<DcChat>(entity: chat.entity, indexesToHighlight: indexes)
        }






        /*
        let contactsWithHighlights: [ContactWithSearchResults] = contacts.map { contact in
            let indexes = contact.contact.containsExact(searchText: searchText)
            return ContactWithSearchResults(contact: contact.contact, indexesToHighlight: indexes)
        }

        filteredContacts = contactsWithHighlights.filter { !$0.indexesToHighlight.isEmpty }
        tableView.reloadData()
        */
    }
}