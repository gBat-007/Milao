import FirebaseFirestore

class EventRepository {
    private let db = Firestore.firestore()

    func createEvent(_ event: Event, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let ref = try db.collection("events").addDocument(from: event)
            completion(.success(ref.documentID))
        } catch {
            completion(.failure(error))
        }
    }

    func joinEvent(inviteCode: String, completion: @escaping (Result<Event, Error>) -> Void) {
        db.collection("events")
            .whereField("inviteCode", isEqualTo: inviteCode)
            .getDocuments { snapshot, error in
                if let e = error { return completion(.failure(e)) }
                guard let data = snapshot?.documents.first?.data(),
                      let event = try? JSONDecoder().decode(Event.self, from: JSONSerialization.data(withJSONObject: data)) else {
                    return completion(.failure(NSError(domain: "", code: 0)))
                }
                completion(.success(event))
            }
    }
}
