local mod	= DBM:NewMod(2557, "DBM-Raids-Dragonflight", 1, 1207)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(208478)
mod:SetEncounterID(2737)
mod:SetUsedIcons(1, 2, 3)
--mod:SetHotfixNoticeRev(20210126000000)
--mod:SetMinSyncRevision(20210126000000)
--mod.respawnTime = 29

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 421672 425401 425400 420933 421616 420415 423117 421703",
	"SPELL_CAST_SUCCESS 421284",
	"SPELL_AURA_APPLIED 421207 419054",
	"SPELL_AURA_APPLIED_DOSE 419054",
	"SPELL_AURA_REMOVED 421207",
--	"SPELL_AURA_REMOVED_DOSE",
	"SPELL_PERIODIC_DAMAGE 421082 423494",
	"SPELL_PERIODIC_MISSED 421082 423494",
--	"UNIT_DIED",
	"UNIT_SPELLCAST_START boss1",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--[[

--]]
--TODO, disgorge targets?
--TODO, chat bubbles for Coiling Flames
--TODO, work out right taunt timing, just swap for each jaws or on venom stacks?
--TODO, add obvious https://www.wowhead.com/ptr-2/spell=424218/combusting-rage if tanks aren't in range?
--mod:AddTimerLine(DBM:EJ_GetSectionInfo(22309))
local warnSperentsFury								= mod:NewCountAnnounce(421672, 3)
local warnMoltenVenom								= mod:NewStackAnnounce(419054, 2, nil, "Tank|Healer")
local warnSerpentsWrath								= mod:NewSpellAnnounce(421703, 4)
local warnVolcanicDisgorge							= mod:NewTargetCountAnnounce(421616, 3, nil, nil, nil, nil, nil, nil, true)

local specWarnCoilingFlames							= mod:NewSpecialWarningYou(421207, nil, nil, nil, 1, 2)
local yellCoilingFlames								= mod:NewShortYell(421207, 7897)--Shortname Flames
local yellCoilingFlamesFades						= mod:NewIconFadesYell(421207)
local specWarnFloodoftheFirleands					= mod:NewSpecialWarningSoakCount(420933, nil, nil, nil, 2, 2)
local specWarnVolcanicDisgorge						= mod:NewSpecialWarningYou(421616, nil, nil, nil, 2, 2)
local yellVolcanicDisgorge							= mod:NewShortYell(421616)
local specWarnScorchtailCrash						= mod:NewSpecialWarningDodgeCount(420415, nil, nil, nil, 3, 2)
local specWarnCataclysmJaws							= mod:NewSpecialWarningDefensive(423117, nil, nil, nil, 1, 2)
local specWarnGTFO									= mod:NewSpecialWarningGTFO(421082, nil, nil, nil, 1, 8)

local timerCoilingFlamesCD							= mod:NewNextCountTimer(70, 421207, 7897, nil, nil, 3)--Shortname Flames
local timerSerpentsFuryCD							= mod:NewNextCountTimer(70, 421672, nil, nil, nil, 3)
local timerFloodoftheFirelandsCD					= mod:NewNextCountTimer(70, 420933, nil, nil, nil, 5)
local timerVolcanicDisgorgeCD						= mod:NewNextCountTimer(10, 421616, nil, nil, nil, 3)
local timerScorchtailCrashCD						= mod:NewCDCountTimer(20, 420415, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
local timerCataclysmJawsCD							= mod:NewNextCountTimer(10, 423117, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON)
--local berserkTimer								= mod:NewBerserkTimer(600)

--mod:AddRangeFrameOption("5/6/10")
--mod:AddInfoFrameOption(407919, true)
mod:AddSetIconOption("SetIconOnCoilingFlames", 421207, true, false, {1, 2, 3})

mod.vb.coilingCount = 0
mod.vb.flamesIcon = 1
mod.vb.furyCount = 0
mod.vb.floodCount = 0
mod.vb.volcanicCount = 0
mod.vb.tailCount = 0
mod.vb.jawsCount = 0

local allTimers = {
	--Cata Jaws
	[423117] = {5.0, 30.0, 30.0, 40.0, 30.0, 40.0, 30.0, 25.0, 25.0, 20.0},
	--Volcanic Disgorge
	[421616] = {30, 20.0, 40.0, 10.0, 10.0, 10.0, 10.0, 30.0, 10.0, 10.0, 10.0, 10.0, 40.0, 20.0}
}

function mod:DisgorgeTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnVolcanicDisgorge:Show()
		specWarnVolcanicDisgorge:Play("targetyou")
		yellVolcanicDisgorge:Yell()
	else
		warnVolcanicDisgorge:Show(self.vb.volcanicCount, targetname)
	end
end

function mod:OnCombatStart(delay)
	self.vb.coilingCount = 0
	self.vb.flamesIcon = 1
	self.vb.furyCount = 0
	self.vb.floodCount = 0
	self.vb.volcanicCount = 0
	self.vb.tailCount = 0
	self.vb.jawsCount = 0
	timerCataclysmJawsCD:Start(5-delay, 1)
	timerSerpentsFuryCD:Start(10-delay, 1)
	timerCoilingFlamesCD:Start(17.5-delay, 1)
	timerScorchtailCrashCD:Start(20-delay, 1)
	timerVolcanicDisgorgeCD:Start(30-delay, 1)
	timerFloodoftheFirelandsCD:Start(70-delay, 1)
end

--function mod:OnCombatEnd()
--	if self.Options.RangeFrame then
--		DBM.RangeCheck:Hide()
--	end
--end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 421672 or spellId == 425401 or spellId == 425400 then--herioc, Unknown, Mythic?
		self.vb.furyCount = self.vb.furyCount + 1
		warnSperentsFury:Show(self.vb.furyCount)
		timerSerpentsFuryCD:Start(nil, self.vb.furyCount+1)
	elseif spellId == 420933 then
		self.vb.floodCount = self.vb.floodCount + 1
		specWarnFloodoftheFirleands:Show(self.vb.floodCount)
		specWarnFloodoftheFirleands:Play("helpsoak")
		timerFloodoftheFirelandsCD:Start(nil, self.vb.floodCount+1)
	elseif spellId == 421616 then
		self.vb.volcanicCount = self.vb.volcanicCount + 1
--		self:BossTargetScanner(args.sourceGUID, "DisgorgeTarget", 0.1, 8, true)
		specWarnVolcanicDisgorge:Show(self.vb.volcanicCount)
		specWarnVolcanicDisgorge:Play("watchstep")
		local timer = self:GetFromTimersTable(allTimers, false, false, spellId, self.vb.volcanicCount+1)
		if timer then
			timerVolcanicDisgorgeCD:Start(timer, self.vb.volcanicCount+1)
		end
--	elseif spellId == 420415 then

	elseif spellId == 423117 then
		self.vb.jawsCount = self.vb.jawsCount + 1
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnCataclysmJaws:Show()
			specWarnCataclysmJaws:Play("defensive")
		else
			--Other tank has this debuff already and it will NOT be gone when cast finishes, TAUNT NOW!
			--This doesn't check TankSwapBehavior dropdown because this always validates that the player about to get hit by this, shouldn't be hit by it
			--if UnitExists("boss1target") and not UnitIsUnit("player", "boss1target") then
			--	local _, _, _, _, _, expireTimeTarget = DBM:UnitDebuff("boss1target", 407547)
			--	if (expireTimeTarget and expireTimeTarget-GetTime() >= 2) and self:AntiSpam(1, 1) then
			--		specWarnFlamingSlashTaunt:Show(UnitName("boss1target"))
			--		specWarnFlamingSlashTaunt:Play("tauntboss")
			--	end
			--end
		end
		local timer = self:GetFromTimersTable(allTimers, false, false, spellId, self.vb.jawsCount+1)
		if timer then
			timerCataclysmJawsCD:Start(timer, self.vb.jawsCount+1)
		end
	elseif spellId == 421703 then
		warnSerpentsWrath:Show()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 421284 then
		self.vb.flamesIcon = 1
		self.vb.coilingCount = self.vb.coilingCount + 1
		timerCoilingFlamesCD:Start(nil, self.vb.coilingCount)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 421207 then
		local icon = self.vb.flamesIcon
		if self.Options.SetIconOnCoilingFlames then
			self:SetIcon(args.destName, icon)
		end
		if args:IsPlayer() then
			specWarnCoilingFlames:Show()
			specWarnCoilingFlames:Play("targetyou")
			yellCoilingFlames:Yell()
			yellCoilingFlamesFades:Countdown(spellId, nil, icon)
		end
	elseif spellId == 419054 then
		local uId = DBM:GetRaidUnitId(args.destName)
		if self:IsTanking(uId) then
			local amount = args.amount or 1
--			local _, _, _, _, _, expireTime = DBM:UnitDebuff("player", spellId)
--			local remaining
--			if expireTime then
--				remaining = expireTime-GetTime()
--			end
--			local timer = (self:GetFromTimersTable(allTimers, difficultyName, false, 376279, self.vb.slamCount+1) or 17.9) - 5
--			if (not remaining or remaining and remaining < timer) and not UnitIsDeadOrGhost("player") and not self:IsHealer() then
--				specWarnConcussiveSlamTaunt:Show(args.destName)
--				specWarnConcussiveSlamTaunt:Play("tauntboss")
--			else
				warnMoltenVenom:Show(args.destName, amount)
--			end
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 421207 then
		if self.Options.SetIconOnCoilingFlames then
			self:SetIcon(args.destName, 0)
		end
		if args:IsPlayer() then
			yellCoilingFlamesFades:Cancel()
		end
	end
end
--mod.SPELL_AURA_REMOVED_DOSE = mod.SPELL_AURA_REMOVED

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if (spellId == 423494 or spellId == 421082) and destGUID == UnitGUID("player") and self:AntiSpam(2, 4) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

--[[
function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 165067 then

	end
end
--]]

--"<31.18 15:55:30> [UNIT_SPELLCAST_START] Volcoross(75.6%-43.0%){Target:Nnoggie} -Volcanic Disgorge- 2.5s [[boss1:Cast-3-5773-2549-5244-421616-0099903FD1:421616]]",
--"<31.18 15:55:30> [CLEU] SPELL_CAST_START#Creature-0-5773-2549-5244-208478-0000103F2B#Volcoross(75.6%-43.0%)##nil#421616#Volcanic Disgorge#nil#nil",
--"<31.20 15:55:30> [UNIT_TARGET] boss1#Volcoross#Target: ??#TargetOfTarget: ??",
--"<31.69 15:55:30> [UNIT_TARGET] boss1#Volcoross#Target: Revvezt#TargetOfTarget: Volcoross",
function mod:UNIT_SPELLCAST_START(uId, _, spellId)
	if spellId == 421616 then
		self:BossUnitTargetScanner(uId, "DisgorgeTarget", 1.1, true)--Allow tank true
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId)
	if spellId == 421684 then--Scorchtail Crash
		self.vb.tailCount = self.vb.tailCount + 1
		specWarnScorchtailCrash:Show(self.vb.tailCount)
		specWarnScorchtailCrash:Play("watchstep")
		timerScorchtailCrashCD:Start(nil, self.vb.tailCount+1)
	end
end

