import Foundation
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFirestore

/// Generic Firestore CRUD helper — all operations are scoped to `users/{uid}/`.
struct FirebaseService: Sendable {
    private let db = Firestore.firestore()

    // MARK: - Collection Reference

    /// Returns a Firestore collection scoped to the current authenticated user.
    func userCollection(_ name: String) -> CollectionReference {
        guard let uid = Auth.auth().currentUser?.uid else {
            fatalError("FirebaseService: No authenticated user. Sign in before accessing Firestore.")
        }
        return db.collection("users").document(uid).collection(name)
    }

    // MARK: - Create

    @discardableResult
    func add<T: Codable>(_ item: T, to collection: String) async throws -> String {
        let ref = try userCollection(collection).addDocument(from: item)
        return ref.documentID
    }

    // MARK: - Read

    func fetch<T: Codable>(from collection: String, source: FirestoreSource = .default) async throws -> [T] {
        let snapshot = try await userCollection(collection).getDocuments(source: source)
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: T.self)
        }
    }

    func fetchDocument<T: Codable>(from collection: String, id: String, source: FirestoreSource = .default) async throws -> T? {
        let doc = try await userCollection(collection).document(id).getDocument(source: source)
        return try? doc.data(as: T.self)
    }

    // MARK: - Update

    func update<T: Codable>(_ item: T, in collection: String, id: String) async throws {
        try userCollection(collection).document(id).setData(from: item, merge: true)
    }

    // MARK: - Delete

    func delete(from collection: String, id: String) async throws {
        try await userCollection(collection).document(id).delete()
    }

    // MARK: - Real-Time Listeners

    /// Listens for real-time updates to an entire collection.
    func listen<T: Codable>(
        to collection: String,
        completion: @escaping @Sendable ([T]) -> Void
    ) -> ListenerRegistration {
        userCollection(collection).addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("FirebaseService: Listen error on \(collection): \(error?.localizedDescription ?? "unknown")")
                completion([])
                return
            }
            let items = documents.compactMap { doc in
                try? doc.data(as: T.self)
            }
            completion(items)
        }
    }

    /// Listens for real-time updates to a single document.
    func listenToDocument<T: Codable>(
        in collection: String,
        id: String,
        completion: @escaping @Sendable (T?) -> Void
    ) -> ListenerRegistration {
        userCollection(collection).document(id).addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot else {
                print("FirebaseService: Listen error on \(collection)/\(id): \(error?.localizedDescription ?? "unknown")")
                completion(nil)
                return
            }
            completion(try? snapshot.data(as: T.self))
        }
    }
}
