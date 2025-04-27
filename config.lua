Config = {}

Config.Debug = false -- Set to true for debug messages

-- Job settings
Config.JobName = "cleaner" -- Must match the job name in QB-Core shared jobs.lua
Config.CleaningTime = 30 -- Seconds it takes to clean a scene
Config.PayPerScene = math.random(150, 350) -- Payment range per cleaned scene

-- Vehicle settings
Config.VehicleModel = "speedo" -- Vehicle model for job
Config.VehicleSpawnLocation = vector4(1157.54, -1466.37, 34.69, 357.82) -- Where the job vehicle spawns

-- Cleaning equipment - used for animations and props
Config.CleaningEquipment = {
    prop = "prop_tool_mopbucket", -- Prop used during cleaning
    bone = 28422, -- Which bone to attach the prop to
    offset = vector3(0.0, -0.25, -0.15), -- Position offset
    rotation = vector3(0.0, 0.0, 0.0) -- Rotation offset
}

-- Job center location
Config.JobCenter = vector3(1155.23, -1463.87, 34.86) -- Where players can start/end shifts

-- Crime scene locations (these will be randomized)
Config.CrimeScenes = {
    [1] = {
        coords = vector3(232.61, -1360.78, 28.65),
        heading = 135.68,
        label = "Alleyway Incident"
    },
    [2] = {
        coords = vector3(-53.79, -1586.59, 29.59),
        heading = 50.12,
        label = "Gas Station Mess"
    },
    [3] = {
        coords = vector3(458.82, -1017.38, 28.25),
        heading = 90.51,
        label = "Police Station Entrance"
    },
    [4] = {
        coords = vector3(297.94, -584.03, 43.26),
        heading = 77.31,
        label = "Hospital Spill"
    },
    [5] = {
        coords = vector3(1207.19, -1477.4, 34.84),
        heading = 80.8,
        label = "Street Corner Cleanup"
    },
    [6] = {
        coords = vector3(-1120.47, -1609.79, 4.39),
        heading = 124.17,
        label = "Beach Incident"
    },
    [7] = {
        coords = vector3(89.16, -1745.31, 30.08),
        heading = 320.86,
        label = "Club Aftermath"
    },
    [8] = {
        coords = vector3(-1393.48, -581.2, 30.27),
        heading = 31.24,
        label = "Bahama Mamas Exterior"
    },
    [9] = {
        coords = vector3(-1037.15, -1397.09, 5.55),
        heading = 70.8,
        label = "Vespucci Canals"
    },
    [10] = {
        coords = vector3(940.08, -1489.06, 30.1),
        heading = 277.36,
        label = "Factory District"
    }
}

-- Blip settings
Config.Blips = {
    jobCenter = {
        sprite = 464,
        color = 25,
        scale = 0.7,
        label = "Crime Scene Cleaners"
    },
    crimeScene = {
        sprite = 398,
        color = 1,
        scale = 0.65,
        label = "Crime Scene"
    }
}

-- UI settings
Config.UI = {
    position = "right-center", -- UI position on screen
    theme = "dark" -- UI theme
}