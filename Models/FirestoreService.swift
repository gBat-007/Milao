//import Foundation
//import FirebaseFirestore
//import Combine // For @Published
//
//class FirestoreService: ObservableObject {
//    private let db = Firestore.firestore()
//    private var listenerRegistration: ListenerRegistration? // To manage realtime listeners
//
//    // @Published properties will automatically update SwiftUI views
//    @Published var todoItems: [TodoItem] = []
//    @Published var errorMessage: String?
//
//    // MARK: - Initializer & Deinitializer
//    // Start listening when the service is initialized
//    init() {
//        // You might want to subscribe to items for a specific user if authenticated
//        // For simplicity, we'll fetch all items initially.
//        // Call subscribeToTodoItems() here or when a user is logged in.
//    }
//
//    // Clean up listener when the service is deallocated to prevent memory leaks
//    deinit {
//        unsubscribeFromTodoItems()
//    }
//
//    // MARK: - CRUD Operations (with async/await)
//
//    // Create (Add)
////    func addTodoItem(title: String, userId: String?) async {
////        do {
////            let newItem = TodoItem(title: title, userId: userId)
////            _ = try db.collection("todoItems").addDocument(from: newItem)
////            print("Todo item added successfully!")
////            errorMessage = nil
////        } catch {
////            print("Error adding todo item: \(error.localizedDescription)")
////            errorMessage = "Failed to add item: \(error.localizedDescription)"
////        }
////    }
//
//    // Read (Fetch all, Realtime Listener)
//    func subscribeToTodoItems() {
//        // If there's an existing listener, remove it first
//        unsubscribeFromTodoItems()
//
//        // You might filter by userId here:
//        // .whereField("userId", isEqualTo: Auth.auth().currentUser?.uid ?? "")
//        listenerRegistration = db.collection("todoItems")
//            .order(by: "createdAt", descending: true) // Order by creation date
//            .addSnapshotListener { [weak self] querySnapshot, error in
//                guard let self = self else { return }
//
//                if let error = error {
//                    print("Error fetching documents: \(error.localizedDescription)")
//                    DispatchQueue.main.async { // Ensure UI updates on main thread
//                        self.errorMessage = "Failed to load items: \(error.localizedDescription)"
//                    }
//                    return
//                }
//
//                guard let documents = querySnapshot?.documents else {
//                    print("No documents found.")
//                    DispatchQueue.main.async {
//                        self.todoItems = []
//                        self.errorMessage = nil
//                    }
//                    return
//                }
//
//                // Map documents to TodoItem using Codable
//                let fetchedItems = documents.compactMap { document -> TodoItem? in
//                    do {
//                        return try document.data(as: TodoItem.self)
//                    } catch {
//                        print("Error decoding document \(document.documentID): \(error.localizedDescription)")
//                        DispatchQueue.main.async {
//                            self.errorMessage = "Error processing item: \(error.localizedDescription)"
//                        }
//                        return nil
//                    }
//                }
//                DispatchQueue.main.async {
//                    self.todoItems = fetchedItems
//                    self.errorMessage = nil // Clear any previous error
//                }
//            }
//    }
//
//    func unsubscribeFromTodoItems() {
//        listenerRegistration?.remove()
//        listenerRegistration = nil
//        print("Firestore listener removed.")
//    }
//
//    // Update
//    func updateTodoItem(item: TodoItem) async {
//        guard let id = item.id else {
//            print("Error: Todo item has no ID for update.")
//            errorMessage = "Item cannot be updated: missing ID."
//            return
//        }
//
//        do {
//            // setData(from:) will replace the entire document.
//            // Use merge: true with setData or updateData if you only want to update specific fields.
//            try await db.collection("todoItems").document(id).setData(from: item)
//            print("Todo item updated successfully!")
//            errorMessage = nil
//        } catch {
//            print("Error updating todo item: \(error.localizedDescription)")
//            errorMessage = "Failed to update item: \(error.localizedDescription)"
//        }
//    }
//
//    // Delete
//    func deleteTodoItem(id: String) async {
//        do {
//            try await db.collection("todoItems").document(id).delete()
//            print("Todo item deleted successfully!")
//            errorMessage = nil
//        } catch {
//            print("Error deleting todo item: \(error.localizedDescription)")
//            errorMessage = "Failed to delete item: \(error.localizedDescription)"
//        }
//    }
//
//    // MARK: - Example of a single fetch (not realtime) using async/await
//    func fetchSingleTodoItem(id: String) async -> TodoItem? {
//        do {
//            let document = try await db.collection("todoItems").document(id).getDocument()
//            let item = try document.data(as: TodoItem.self)
//            return item
//        } catch {
//            print("Error fetching single todo item: \(error.localizedDescription)")
//            errorMessage = "Failed to fetch single item: \(error.localizedDescription)"
//            return nil
//        }
//    }
//}
