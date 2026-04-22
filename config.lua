Config = {}

Config.Debug = false

Config.Framework = 'auto' -- auto | qbcore | qbox | esx | standalone
Config.FrameworkResource = {
    qbcore = 'qb-core',
    qbox = 'qbx_core',
    esx = 'es_extended'
}

Config.Inventory = 'auto' -- auto | qb-inventory | ox_inventory | esx_inventory | qs-inventory | standalone
Config.InventoryResource = {
    ['qb-inventory'] = 'qb-inventory',
    ['ox_inventory'] = 'ox_inventory',
    ['esx_inventory'] = 'esx_inventoryhud',
    ['qs-inventory'] = 'qs-inventory'
}

Config.Fuel = {
    enabled = false,
    system = 'auto', -- auto | LegacyFuel | CDN-Fuel | ox_fuel | qb-fuel | none
    resources = {
        ['LegacyFuel'] = 'LegacyFuel',
        ['CDN-Fuel'] = 'cdn-fuel',
        ['ox_fuel'] = 'ox_fuel',
        ['qb-fuel'] = 'qb-fuel'
    }
}

Config.Items = {
    bait = 'fishbait',
    rod = 'fishingrod',
    fishNet = 'fishnet'
}

Config.BaitConsumeChance = 0.60
Config.WaitForBiteMs = { min = 10000, max = 20000 }

Config.FishLists = {
    { name = 'sturgeon', minPrice = 150, maxPrice = 800, minLength = 50, maxLength = 200 },
    { name = 'whitefish', minPrice = 20, maxPrice = 60, minLength = 20, maxLength = 70 },
    { name = 'codfish', minPrice = 100, maxPrice = 400, minLength = 30, maxLength = 120 },
    { name = 'mackerel', minPrice = 15, maxPrice = 60, minLength = 20, maxLength = 40 },
    { name = 'alewife', minPrice = 10, maxPrice = 30, minLength = 15, maxLength = 25 },
    { name = 'carp', minPrice = 20, maxPrice = 100, minLength = 30, maxLength = 80 },
    { name = 'catfish', minPrice = 25, maxPrice = 120, minLength = 40, maxLength = 100 },
    { name = 'whitesucker', minPrice = 10, maxPrice = 50, minLength = 20, maxLength = 60 },
    { name = 'redhorse', minPrice = 10, maxPrice = 50, minLength = 20, maxLength = 60 },
    { name = 'salmon', minPrice = 40, maxPrice = 200, minLength = 60, maxLength = 150 },
    { name = 'herring', minPrice = 5, maxPrice = 20, minLength = 10, maxLength = 30 },
    { name = 'bass', minPrice = 30, maxPrice = 150, minLength = 30, maxLength = 70 }
}
