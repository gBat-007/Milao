import EventKit
import Foundation

final class PersonalCalendarWriter {
    private let eventStore = EKEventStore()

    func add(_ event: Event, completion: @escaping (Result<Void, Error>) -> Void) {
        let saveEvent: () -> Void = { [eventStore] in
            guard let calendar = eventStore.defaultCalendarForNewEvents else {
                DispatchQueue.main.async {
                    completion(.failure(CalendarWriteError.noDefaultCalendar))
                }
                return
            }

            let calendarEvent = EKEvent(eventStore: eventStore)
            calendarEvent.title = "\(event.emoji) \(event.title)"
            calendarEvent.startDate = event.eventDate
            calendarEvent.endDate = Calendar.current.date(
                byAdding: .hour,
                value: 1,
                to: event.eventDate
            ) ?? event.eventDate.addingTimeInterval(60 * 60)
            calendarEvent.calendar = calendar
            calendarEvent.notes = "Milao event · Invite code: \(event.id)"

            do {
                try eventStore.save(calendarEvent, span: .thisEvent)
                DispatchQueue.main.async { completion(.success(())) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }

        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:
            saveEvent()
        case .notDetermined:
            eventStore.requestFullAccessToEvents { granted, error in
                guard granted else {
                    DispatchQueue.main.async {
                        completion(.failure(error ?? CalendarWriteError.accessDenied))
                    }
                    return
                }
                saveEvent()
            }
        case .writeOnly, .denied, .restricted:
            completion(.failure(CalendarWriteError.accessDenied))
        @unknown default:
            completion(.failure(CalendarWriteError.accessDenied))
        }
    }
}

private enum CalendarWriteError: LocalizedError {
    case accessDenied
    case noDefaultCalendar

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access was not granted. Allow full calendar access in Settings to add this event."
        case .noDefaultCalendar:
            return "No default calendar is available on this device. Set a default calendar in Calendar settings and try again."
        }
    }
}
