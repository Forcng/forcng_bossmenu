local isShowingLib = false
local nearMenu = nil

CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        local playerData = ESX.GetPlayerData()

        nearMenu = nil

        for job, data in pairs(Config.BossMenus) do
            if playerData.job and playerData.job.name == job then
                local dist = #(playerCoords - data.location)
                if dist < 10 then
                    sleep = 0
                    DrawMarker(1, data.location.x, data.location.y, data.location.z - 1.0, 0, 0, 0, 0, 0, 0, 1.5, 1.5, 0.3, 160, 32, 240, 150, false, true, 2, false, nil, nil, false)
                    if dist < 1.5 then
                        nearMenu = { job = job, minGrade = data.minGrade }
                        if not isShowingLib then
                            lib.showTextUI('[E] Open Boss Menu', { position = 'right-center' })
                            isShowingLib = true
                        end
                    end
                end
            end
        end

        if not nearMenu and isShowingLib then
            lib.hideTextUI()
            isShowingLib = false
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if nearMenu and IsControlJustReleased(0, 38) then
            ESX.TriggerServerCallback('forcng_bossMenu:ownBusiness', function(ownBusiness, grade)
                if ownBusiness or grade >= nearMenu.minGrade then
                    openBossMenu()
                else
                    lib.notify({ title = 'Boss Menu', description = 'You are not the boss!', type = 'error', position = 'center-right' })
                end
            end)
        end
    end
end)

function openBossMenu()
    local jobName = nearMenu.job:gsub("^%l", string.upper)
    local menuTitle = jobName .. ' Boss Menu'

    lib.registerContext({
        id = 'boss_menu',
        title = menuTitle,
        options = {
            {
                title = 'View Company Funds',
                onSelect = function()
                    ESX.TriggerServerCallback('forcng_bossMenu:getCompanyFunds', function(balance)
                        lib.notify({
                            title = jobName .. ' Funds',
                            description = 'Balance: $' .. balance,
                            type = 'inform',
                            position = 'center-right',
                            icon = 'fa-solid fa-person-walking-luggage'
                        })
                    end)
                end
            },
            {
                title = 'Hire Employee',
                onSelect = function()
                    local input = lib.inputDialog('Hire Employee', { 'Player ID', 'Grade' })
                    if input and input[1] and input[2] then
                        TriggerServerEvent('forcng_bossMenu:hireEmployee', tonumber(input[1]), tonumber(input[2]))
                    end
                end
            },
            {
                title = 'Manage Employees',
                onSelect = function()
                    ESX.TriggerServerCallback('forcng_bossMenu:getEmployees', function(employees)
                        if #employees == 0 then
                            lib.notify({
                                title = 'Info',
                                description = 'No employees found.',
                                type = 'info',
                                position = 'center-right'
                            })
                            return
                        end

                        local empOptions = {}
                        for _, emp in ipairs(employees) do
                            table.insert(empOptions, {
                                title = emp.name .. ' (Grade ' .. emp.grade .. ')',
                                onSelect = function()
                                    openEmployeeMenu(emp)
                                end
                            })
                        end

                        lib.registerContext({
                            id = 'employee_list',
                            title = jobName .. ' Employee List',
                            menu = 'boss_menu',
                            options = empOptions
                        })

                        lib.showContext('employee_list')
                    end)
                end
            },
            {
                title = 'Deposit Company Funds',
                onSelect = function()
                    local input = lib.inputDialog('Deposit Funds', { 'Amount' })
                    if input and input[1] then
                        TriggerServerEvent('forcng_bossMenu:depositMoney', tonumber(input[1]))
                    end
                end
            },
            {
                title = 'Withdraw Company Funds',
                onSelect = function()
                    local input = lib.inputDialog('Withdraw Funds', { 'Amount' })
                    if input and input[1] then
                        TriggerServerEvent('forcng_bossMenu:withdrawMoney', tonumber(input[1]))
                    end
                end
            }
        }
    })

    lib.showContext('boss_menu')
end

function openEmployeeMenu(emp)
    lib.registerContext({
        id = 'emp',
        title = emp.name .. ' (Grade ' .. emp.grade .. ')',
        menu = 'employee_list',
        options = {
            {
                title = 'Fire Employee',
                icon = 'user-minus',
                onSelect = function()
                    TriggerServerEvent('forcng_bossMenu:fireEmployee', emp.identifier)
                end
            },
            {
                title = 'Demote Employee',
                icon = 'arrow-down',
                onSelect = function()
                    local input = lib.inputDialog('Demote Employee', { 'New Grade' })
                    if input and input[1] then
                        TriggerServerEvent('forcng_bossMenu:demoteEmployee', emp.identifier, tonumber(input[1]))
                    end
                end
            },
            {
                title = 'Promote Employee',
                icon = 'arrow-up',
                onSelect = function()
                    local input = lib.inputDialog('Promote Employee', { 'New Grade' })
                    if input and input[1] then
                        TriggerServerEvent('forcng_bossMenu:promoteEmployee', emp.identifier, tonumber(input[1]))
                    end
                end
            }
        }
    })
    lib.showContext('emp')
end
