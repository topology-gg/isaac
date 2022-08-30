import { toBN } from 'starknet/utils/number';
import DEVICE_DIM_MAP from '../../components/ConstantDeviceDimMap';
import { DEVICE_RESOURCE_MAP } from '../../components/ConstantDeviceResources'

//
// Function to build mapping from device id to device info for various device classes
//
export default function gridMappingFromData(
    db_pgs,
    db_harvesters,
    db_transformers,
    db_upsfs,
    db_ndpes,
    db_deployed_devices
) {
    let gridMapping = {};

    //
    // Build mapping for device id => resource & energy balances
    //
    const pg_mapping = new Map();
    for (const pg of db_pgs.pgs) {
        pg_mapping.set(pg["id"], {
            energy: pg["energy"],
        });
    }

    // ref: https://stackoverflow.com/questions/10640159/key-for-javascript-dictionary-is-not-stored-as-value-but-as-variable-name
    const harvester_mapping = new Map();
    for (const harvester of db_harvesters.harvesters) {
        const resource_type = DEVICE_RESOURCE_MAP[harvester["type"]];

        harvester_mapping.set(harvester["id"], {
            [resource_type]: harvester["resource"],
            energy: harvester["energy"],
        });
    }

    const transformer_mapping = new Map();
    for (const transformer of db_transformers.transformers) {
        const resource_type_pre =
            DEVICE_RESOURCE_MAP[transformer["type"]]["pre"];
        const resource_type_post =
            DEVICE_RESOURCE_MAP[transformer["type"]]["post"];

        transformer_mapping.set(transformer["id"], {
            [resource_type_pre]: transformer["resource_pre"],
            [resource_type_post]: transformer["resource_post"],
            energy: transformer["energy"],
        });
    }

    const upsf_mapping = new Map();
    for (const upsf of db_upsfs.upsfs) {
        upsf_mapping.set(upsf["id"], {
            "FE raw": upsf["resource_0"],
            "AL raw": upsf["resource_2"],
            "CU raw": upsf["resource_4"],
            "SI raw": upsf["resource_6"],
            "PU raw": upsf["resource_8"],
            "FE refined": upsf["resource_1"],
            "AL refined": upsf["resource_3"],
            "CU refined": upsf["resource_5"],
            "SI refined": upsf["resource_7"],
            "PU enriched": upsf["resource_9"],
            Energy: upsf["energy"],
        });
    }

    const ndpe_mapping = new Map();
    for (const ndpe of db_ndpes.ndpes) {
        ndpe_mapping.set(ndpe["id"], {
            energy: ndpe["energy"],
        });
    }

    var base_grid_str_drawn = [];
    for (const entry of db_deployed_devices.deployed_devices) {
        const x = entry.grid.x;
        const y = entry.grid.y;
        const typ = parseInt(entry.type);
        const id = entry.id;

        const owner_hexstr = toBN(entry.owner).toString(16);
        const owner_hexstr_abbrev =
            "0x" + owner_hexstr.slice(0, 3) + "..." + owner_hexstr.slice(-4);

        const device_dim = DEVICE_DIM_MAP.get(typ);

        var balances;
        if ([0, 1].includes(typ)) {
            balances = pg_mapping.get(id);
        } else if ([2, 3, 4, 5, 6].includes(typ)) {
            balances = harvester_mapping.get(id);
        } else if ([7, 8, 9, 10, 11].includes(typ)) {
            balances = transformer_mapping.get(id);
        } else if (typ == 14) {
            balances = upsf_mapping.get(id);
        } else if (typ == 15) {
            balances = ndpe_mapping.get(id);
        } else {
            balances = {};
        }

        var base_grid;
        if ("base_grid" in entry) {
            // base_grid is a key => entry is a grid with deployed device of non-utx type
            base_grid = entry.base_grid;
            const base_grid_str = `(${base_grid.x},${base_grid.y})`;
            if (base_grid_str_drawn.includes(base_grid_str)) {
                continue;
            }
            base_grid_str_drawn.push(base_grid_str);
        } else {
            // base_grid not a key => entry is a grid with deployed utx
            base_grid = entry.grid;
        }

        for (const i = 0; i < device_dim; i++) {
            for (const j = 0; j < device_dim; j++) {
                gridMapping[`(${base_grid.x + i},${base_grid.y + j})`] = {
                    owner: owner_hexstr_abbrev,
                    id: id,
                    type: typ,
                    balances: balances,
                };
            }
        }

        // Use device dimension to insert entry into grid mapping (every device is a square)
        // for (const i=0; i<device_dim; i++) {
        //     for (const j=0; j<device_dim; j++) {
        //         _gridMapping.current [`(${x+i},${y+j})`] = {
        //             'owner' : owner_hexstr_abbrev,
        //             'type' : typ,
        //             'balances' : balances
        //         }
        //     }
        // }
    }

    return gridMapping;
}
