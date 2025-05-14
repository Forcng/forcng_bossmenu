local function ownBusiness(xPlayer)
    local job = xPlayer.job.name
    local grade = xPlayer.job.grade
    local jobConfig = Config.BossMenus[job]
    return jobConfig and grade >= jobConfig.minGrade
end

ESX.RegisterServerCallback('forcng_bossMenu:ownBusiness', function(source, cb)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    cb(ownBusiness(xPlayer), xPlayer.job.grade)
end)

ESX.RegisterServerCallback('forcng_bossMenu:getCompanyFunds', function(source, cb)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local society = 'society_' .. xPlayer.job.name
    exports.oxmysql:fetch('SELECT money FROM addon_account_data WHERE account_name = ?', {society}, function(result)
        cb(result and result[1] and result[1].money or 0)
    end)
end)

ESX.RegisterServerCallback('forcng_bossMenu:getEmployees', function(source, cb)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not ownBusiness(xPlayer) then return cb({}) end

    local job = xPlayer.job.name

    exports.oxmysql:fetch('SELECT identifier, firstname, lastname, job_grade FROM users WHERE job = ?', {job}, function(result)
        local employees = {}

        for _, row in ipairs(result) do
            local grade = tonumber(row.job_grade) or 0
            local name = (row.firstname or '') .. ' ' .. (row.lastname or '')

            table.insert(employees, {
                identifier = row.identifier,
                name = name,
                grade = grade
            })
        end

        cb(employees)
    end)
end)

-- Events
RegisterServerEvent('forcng_bossMenu:hireEmployee')
AddEventHandler('forcng_bossMenu:hireEmployee', function(targetId, grade)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local target = ESX.GetPlayerFromId(targetId)
    if not ownBusiness(xPlayer) or not target then return end
    target.setJob(xPlayer.job.name, grade)

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Hired',
        description = 'You hired ' .. target.getName(),
        type = 'success',
        position = 'center-right',
        icon = 'user-plus'
    })

    TriggerClientEvent('ox_lib:notify', targetId, {
        title = 'Hired',
        description = 'You were hired as ' .. xPlayer.job.label,
        type = 'inform',
        position = 'center-right',
        icon = 'briefcase'
    })
end)

RegisterServerEvent('forcng_bossMenu:fireEmployee')
AddEventHandler('forcng_bossMenu:fireEmployee', function(identifier)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not ownBusiness(xPlayer) then return end
    local target = ESX.GetPlayerFromIdentifier(identifier)
    if target then
        target.setJob('unemployed', 0)
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Fired',
            description = 'You fired ' .. target.getName(),
            type = 'success',
            position = 'center-right',
            icon = 'user-minus'
        })

        TriggerClientEvent('ox_lib:notify', target.source, {
            title = 'Fired',
            description = 'You were fired from ' .. xPlayer.job.label,
            type = 'inform',
            position = 'center-right',
            icon = 'briefcase'
        })
    else
        MySQL.update('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', {'unemployed', 0, identifier}, function(isSuccess)
            local msg = isSuccess > 0 and 'You fired an offline employee.' or 'Employee not found.'
            TriggerClientEvent('ox_lib:notify', source, {
                title = isSuccess > 0 and 'Fired' or 'Error',
                description = isSuccess > 0 and 'You fired an offline employee.' or 'Employee not found.',
                type = isSuccess > 0 and 'success' or 'error',
                position = 'center-right',
                icon = isSuccess > 0 and 'user-minus' or 'x'
            })
        end)
    end
end)

RegisterServerEvent('forcng_bossMenu:demoteEmployee')
AddEventHandler('forcng_bossMenu:demoteEmployee', function(identifier, newGrade)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not ownBusiness(xPlayer) then return end
    local target = ESX.GetPlayerFromIdentifier(identifier)
    if target then
        target.setJob(xPlayer.job.name, newGrade)
               TriggerClientEvent('ox_lib:notify', source, {
            title = 'Demoted',
            description = 'You demoted ' .. target.getName() .. ' to grade ' .. newGrade,
            type = 'success',
            position = 'center-right',
            icon = 'arrow-down'
        })

        TriggerClientEvent('ox_lib:notify', target.source, {
            title = 'Demoted',
            description = 'You were demoted to grade ' .. newGrade,
            type = 'inform',
            position = 'center-right',
            icon = 'arrow-down'
        })
    else
        MySQL.update('UPDATE users SET job_grade = ? WHERE identifier = ?', {newGrade, identifier}, function(isSuccess)
            local msg = isSuccess > 0 and 'Demoted offline employee.' or 'Employee not found.'
            TriggerClientEvent('ox_lib:notify', source, {
                title = isSuccess > 0 and 'Demoted' or 'Error',
                description = isSuccess > 0 and 'Demoted offline employee.' or 'Employee not found.',
                type = isSuccess > 0 and 'success' or 'error',
                position = 'center-right',
                icon = isSuccess > 0 and 'arrow-down' or 'x'
            })
        end)
    end
end)

RegisterServerEvent('forcng_bossMenu:withdrawMoney')
AddEventHandler('forcng_bossMenu:withdrawMoney', function(amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not ownBusiness(xPlayer) then return end
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    local society = 'society_' .. xPlayer.job.name
    exports.oxmysql:fetch('SELECT money FROM addon_account_data WHERE account_name = ?', {society}, function(result)
        if result and result[1] and result[1].money >= amount then
            MySQL.update('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', {amount, society})
            xPlayer.addMoney(amount)
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Withdrawn',
                description = 'Withdrew $' .. amount,
                type = 'success',
                position = 'center-right',
                icon = 'fa-solid fa-money-bill-wave'
            })
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Error',
                description = 'Not enough company funds.',
                type = 'error',
                position = 'center-right',
                icon = 'fa-solid fa-money-bill-wave'
            })
        end
    end)
end)

RegisterServerEvent('forcng_bossMenu:depositMoney')
AddEventHandler('forcng_bossMenu:depositMoney', function(amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not ownBusiness(xPlayer) then return end
    amount = tonumber(amount)
    if not amount or amount <= 0 or xPlayer.getMoney() < amount then return end
    local society = 'society_' .. xPlayer.job.name
    xPlayer.removeMoney(amount)
    MySQL.update('UPDATE addon_account_data SET money = money + ? WHERE account_name = ?', {amount, society})
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Deposited',
        description = 'Deposited $' .. amount,
        type = 'success',
        position = 'center-right',
        icon = 'fa-solid fa-money-bill-wave'
    })
end)

RegisterServerEvent('forcng_bossMenu:promoteEmployee')
AddEventHandler('forcng_bossMenu:promoteEmployee', function(identifier, newGrade)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not ownBusiness(xPlayer) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You are not authorized to promote employees.',
            type = 'error',
            position = 'center-right'
        })
        return
    end

    local targetPlayer = ESX.GetPlayerFromIdentifier(identifier)
    if targetPlayer then
        targetPlayer.setJob(xPlayer.job.name, newGrade)

        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Promoted',
            description = 'You promoted ' .. targetPlayer.getName() .. ' to grade ' .. newGrade,
            type = 'success',
            position = 'center-right',
            icon = 'arrow-up'
        })

        TriggerClientEvent('ox_lib:notify', targetPlayer.source, {
            title = 'Promotion',
            description = 'You have been promoted to grade ' .. newGrade .. ' in ' .. xPlayer.job.label,
            type = 'inform',
            position = 'center-right',
            icon = 'arrow-up'
        })
    else
        MySQL.update('UPDATE users SET job_grade = ? WHERE identifier = ?', { newGrade, identifier }, function(isSuccess)
            TriggerClientEvent('ox_lib:notify', source, {
                title = isSuccess > 0 and 'Promoted' or 'Error',
                description = isSuccess > 0 and 'You promoted the offline employee to grade ' .. newGrade or 'No offline employee found with that identifier.',
                type = isSuccess > 0 and 'success' or 'error',
                position = 'center-right',
                icon = isSuccess > 0 and 'arrow-up' or 'x'
            })
        end)
    end
end)