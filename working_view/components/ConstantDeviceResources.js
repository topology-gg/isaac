export const DEVICE_RESOURCE_MAP = {
    2: "FE raw",
    3: "AL raw",
    4: "CU raw",
    5: "SI raw",
    6: "PU raw",
    7: {'pre':'FE raw', 'post':'FE refined'},
    8:  {'pre':'AL raw', 'post':'AL refined'},
    9:  {'pre':'CU raw', 'post':'CU refined'},
    10: {'pre':'SI raw', 'post':'SI refined'},
    11: {'pre':'PU raw', 'post':'PU enriched'}
}

//  = new Map();
// DEVICE_RESOURCE_MAP.set(2,  "FE raw");
// DEVICE_RESOURCE_MAP.set(3,  "AL raw");
// DEVICE_RESOURCE_MAP.set(4,  "CU raw");
// DEVICE_RESOURCE_MAP.set(5,  "SI raw");
// DEVICE_RESOURCE_MAP.set(6,  "PU raw");
// DEVICE_RESOURCE_MAP.set(7,  {'pre':'FE raw', 'post':'FE refined'});
// DEVICE_RESOURCE_MAP.set(8,  {'pre':'AL raw', 'post':'AL refined'});
// DEVICE_RESOURCE_MAP.set(9,  {'pre':'CU raw', 'post':'CU refined'});
// DEVICE_RESOURCE_MAP.set(10, {'pre':'SI raw', 'post':'SI refined'});
// DEVICE_RESOURCE_MAP.set(11, {'pre':'PU raw', 'post':'PU enriched'});