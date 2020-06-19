mod protos;

use log::debug;
use num_traits::FromPrimitive;
use protobuf::{Message, ProtobufError, ProtobufResult};

use crate::protos::greeting::*;
use crate::protos::MessageType;

#[cfg(target_os = "android")]
use {android_logger::Config, log::Level};

#[allow(clippy::missing_safety_doc)]
#[no_mangle]
pub unsafe extern "C" fn initialize_ffi() {
    #[cfg(target_os = "android")]
    {
        android_logger::init_once(Config::default().with_min_level(Level::Debug));
    }
    debug!("Native FFI Bridge receiver initialized.");
}

#[allow(clippy::missing_safety_doc)]
#[no_mangle]
pub unsafe extern "C" fn receive_from_ffi(
    request_message_type: i32,
    request_message_id: i32,
    payload_buffer: *const u8,
    payload_buffer_length: usize,
    expected_response_message_type: i32,
    response_callback_fn: extern "C" fn(i32, i32, *const u8, usize, u8),
) {
    let request_payload_buffer =
        &std::slice::from_raw_parts(payload_buffer, payload_buffer_length).to_vec();

    let (response_message_type, response_payload, is_response_complete) =
        match FromPrimitive::from_i32(request_message_type) {
            Some(request_message_type) => {
                let (response_message_type, response_payload) = dispatch(
                    request_message_type,
                    FromPrimitive::from_i32(expected_response_message_type),
                    request_payload_buffer,
                );

                (response_message_type as i32, response_payload, 1)
                // TODO: stream responses
                // (accommodated by sending 0 instead of 1 as final argument to Dart callback
                // to indicate more payloads to come - 1 signals end of stream)
            }
            None => (
                -1,
                ProtobufResult::Err(ProtobufError::MessageNotInitialized {
                    message: "Unrecognized message",
                }),
                1,
            ),
        };

    if response_message_type == -1 {
        // Unrecognized message.

        response_callback_fn(-1, request_message_id, Vec::with_capacity(0).as_ptr(), 0, 1);
    } else if expected_response_message_type == -1 {
        // Caller does not expect a reply, no need to do anything.
    } else if response_message_type == expected_response_message_type {
        // Message recognized and valid response prepared; pass back to caller.

        // TODO: will attempt unwrap of response_payload even if it's the ProtobufResult::Err
        // we just set above for an unrecognized message.
        let response_payload_buffer = response_payload.unwrap();

        response_callback_fn(
            response_message_type,
            request_message_id,
            response_payload_buffer.as_ptr(),
            response_payload_buffer.len(),
            is_response_complete,
        );
    } else {
        // We recognized the caller's message and prepared a response, but the response
        // we prepared differs in type from the response the caller is expecting.

        response_callback_fn(-2, request_message_id, Vec::with_capacity(0).as_ptr(), 0, 1);
    }
}

pub(crate) fn dispatch(
    request_message_type: MessageType,
    expected_response_message_type: Option<MessageType>,
    request_payload_buffer: &[u8],
) -> (MessageType, ProtobufResult<Vec<u8>>) {
    match request_message_type {
        MessageType::HelloRequest => {
            let (response_message_type, response) = handle_hello_request_message(
                protobuf::parse_from_bytes(request_payload_buffer).unwrap(),
            );

            (response_message_type, response.write_to_bytes())
        }
        _ => unimplemented!(),
    }
}

fn handle_hello_request_message(request: HelloRequest) -> (MessageType, HelloResponse) {
    let mut response = HelloResponse::new();

    debug!(
        "Rust received a message over FFI with name {}",
        request.get_name()
    );

    response.set_message(format!("Hello from Rust, {}!", request.get_name()));

    (MessageType::HelloResponse, response)
}
