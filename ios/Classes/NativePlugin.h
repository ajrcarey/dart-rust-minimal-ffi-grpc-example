// NOTE: Append the lines below to ios/Classes/<your>Plugin.h

void initialize_ffi(void);

void receive_from_ffi(int32_t request_message_type,
                      int32_t request_message_id,
                      const uint8_t *payload_buffer,
                      uintptr_t payload_buffer_length,
                      int32_t expected_response_message_type,
                      void (*response_callback_fn)(int32_t, int32_t, const uint8_t*, uintptr_t, uint8_t));
