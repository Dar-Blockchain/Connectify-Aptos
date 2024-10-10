module Connectify::DeviceContract {
    use aptos_std::smart_vector;
    use std::string::String;
    use std::signer;



    const EDEVICE_EXISTS: u64 = 1;
    const EDEVICE_NOT_FOUND: u64 = 2;

    struct Device has key {
        serial_number: String,
        model_product: address,
        owner: address,
        personal_data: smart_vector::SmartVector<String>,
    }

    public entry fun initialize_device(account: &signer, serial_number: String, model_product: address) {
        assert!(Connectify::AuthContract::is_whitelisted(signer::address_of(account)), 0); // Check whitelist
        assert!(!does_device_exist(serial_number), EDEVICE_EXISTS);
        let device = Device {
            serial_number,
            model_product,
            owner: signer::address_of(account),
            personal_data: smart_vector::new<String>(),
        };
        move_to(account, device);
    }

    public fun does_device_exist(serial_number: String): bool {
        // Logic to check if a device with the given serial number exists
        // Implementation can be done using a storage structure or events
        false // Placeholder
    }

    public entry fun add_personal_data(account: &signer, device_address: address, data: String) acquires Device {
        assert!(Connectify::AuthContract::is_whitelisted(signer::address_of(account)), 0); // Check whitelist
        let device = borrow_global_mut<Device>(device_address);
        smart_vector::push_back(&mut device.personal_data, data);
    }

    public entry fun transfer_ownership(account: &signer, device_address: address, new_owner: address) acquires Device {
        assert!(Connectify::AuthContract::is_whitelisted(signer::address_of(account)), 0); // Check whitelist
        let device = borrow_global_mut<Device>(device_address);
        device.owner = new_owner; // Update ownership directly
}

    public entry fun submit_event(account: &signer, device_address: address, event_type: String, message: String) acquires Device {
        // Ensure the caller owns the device
        let device = borrow_global<Device>(device_address);
        assert!(device.owner == signer::address_of(account), 0);

        // Submit the event along with manufacturer information
        // let manufacturer = borrow_global<Device>(device.model_product);
        Connectify::EventHandlerContract::submit_event(device_address, event_type, message);
    }

}
