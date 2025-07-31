-- blob.lua
local Blob = {}
Blob.__index = Blob

function Blob:new()
    local self = setmetatable({}, Blob)
    self.vida = 100
    self.max_vida = 100
    self.hambre = 0
    self.sueno = 0
    self.limpieza = 100
    self.oro = 0
    self.mejoras = {}
    self.cartas = {}
    return self
end

function Blob:alimentar()
    if self.oro >= 5 and self.hambre > 0 then
        self.oro = self.oro - 5
        self.hambre = math.max(0, self.hambre - 30)
    end
end

function Blob:dormir()
    if self.oro >= 5 and self.sueno > 0 then
        self.oro = self.oro - 5
        self.sueno = math.max(0, self.sueno - 30)
    end
end

function Blob:banar()
    if self.oro >= 5 and self.limpieza < 100 then
        self.oro = self.oro - 5
        self.limpieza = math.min(100, self.limpieza + 30)
    end
end

return Blob 
-- lo como se noa que no hah mas mafa qiue ahnavwet wxdddddddd
-- using sistmw swicinwkdnfnwcdvgnodkjn kwnnfjkn kjndkjncjnwjnojngj jnwdjif 
--dfjniubuig
--erg e
--euebpia-fwdeg-w
--fwge
--rgjehg
    --fefhefhe
    -- fmnsjdnpnspkjdbgkssjdkbglkfbkwbdkjbvdkhbcwkhbwjktbeqkfjkbghib kjbierbkej bjkebrkjgbjkrbkfjbgkjebjigjnkjnwekjdnkjgnjwekndjibgeibndgjkbgfi3nininrfribergiuebnngenv3
    --fjebibdfjebijcnehiubgiedngfonewiuibsih r
    -- fiueoknojnvejkenenjkvnenkfnkfekovoknekvonvgjfhaut--utesytf
    --ydyytijhojg
--gdzfxigvddjdbfpup snfdg np    npidjgpi  ekjbffgjeinen41pq1ijgnqpirbpiu    beetiboiefñigub :::
-- eeuhpqiuefu  piuedhdiqhefifughqeiufviuefpiuepi5uneuifgnibeiviqjbepighi