# NRP Crime Scene Cleaner

NRP Crime Scene Cleaner is a utility script designed to automate the cleanup of specific files or directories in your project. This script is tailored for QBCore-based FiveM servers.


### QBCore Job Configuration

To integrate the Crime Scene Cleaner job into your QBCore server, add the following code to your `shared/jobs.lua` file:

```lua
["cleaner"] = {
    label = "Crime Scene Cleaner",
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = {
            name = "Trainee",
            payment = 50
        },
        ['1'] = {
            name = "Employee",
            payment = 75
        },
        ['2'] = {
            name = "Senior Cleaner",
            payment = 100
        },
        ['3'] = {
            name = "Manager",
            payment = 125,
            isboss = true
        },
    },
}
```