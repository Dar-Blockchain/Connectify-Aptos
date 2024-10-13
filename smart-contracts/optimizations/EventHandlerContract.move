module Connectify::EventHandlerContract {
    use std::string::String;


    struct Event has key, drop, store {
        device_id: address,
        event_type: String,
        message: String,
    }

    #[event]
    struct EventSubmitted has drop, store {
        device_id : address,
        event_type: String,
        message: String,
    }

    public entry fun submit_event(device_id: address, event_type: String, message: String) {
        let event = Event {
            device_id,
            event_type,
            message,
        };

        emit_event(event)
    }

     fun emit_event(event: Event) {

        let event_notification = EventSubmitted {
            device_id: event.device_id,
            event_type: event.event_type,
            message: event.message,
        };
        0x1::event::emit(event_notification);
    }
}


// this smart contract is lacking a lot 