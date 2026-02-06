# SoftHSM2 Docker Image

## Build and run the image

### With the default version of [SoftHSM](https://github.com/opendnssec/SoftHSMv2/tags)

1.  Build the image

         docker build --tag softhsm-java21 .




## Test it
Docker image write slotNumber file

         pin: "123456"
         certificateSerialNumberHex: 24DE370107BB
         slot = Files.readString(Path.of(System.getenv("SOFTHSM_REAL_SLOT_FILE"))).trim();
         






