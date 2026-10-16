AnimalInseminationEvent = {}

local AnimalInseminationEvent_mt = Class(AnimalInseminationEvent, Event)
InitEventClass(AnimalInseminationEvent, "AnimalInseminationEvent")


function AnimalInseminationEvent.emptyNew()

    local self = Event.new(AnimalInseminationEvent_mt)
    return self

end


function AnimalInseminationEvent.new(object, animal, semen)

	local event = AnimalInseminationEvent.emptyNew()

	event.object = object
	event.animal = animal
	event.semen = semen

	return event

end


function AnimalInseminationEvent:readStream(streamId, connection)

	self.object = NetworkUtil.readNodeObject(streamId)
	self.animal = RLAnimalUtil.readStreamIdentifiers(streamId, connection)
	
	self.semen = { ["genetics"] = {} }

	self.semen.country = streamReadUInt8(streamId)
	self.semen.farmId = streamReadString(streamId)
	self.semen.uniqueId = streamReadString(streamId)
	self.semen.name = streamReadString(streamId)
	self.semen.typeIndex = streamReadUInt8(streamId)
	self.semen.subTypeIndex = streamReadUInt8(streamId)
	self.semen.success = streamReadFloat32(streamId)

	self.semen.genetics.metabolism = streamReadFloat32(streamId)
	self.semen.genetics.fertility = streamReadFloat32(streamId)
	self.semen.genetics.health = streamReadFloat32(streamId)
	self.semen.genetics.quality = streamReadFloat32(streamId)
	self.semen.genetics.productivity = streamReadFloat32(streamId)

	if self.semen.genetics.productivity < 0 then self.semen.genetics.productivity = nil end

	Log:trace("InseminationEvent:readStream semen.country=%s", tostring(self.semen.country))

	self:run(connection)

end


function AnimalInseminationEvent:writeStream(streamId, connection)

	NetworkUtil.writeNodeObject(streamId, self.object)
	RLAnimalUtil.writeStreamIdentifiers(self.animal, streamId, connection)

	local semen = self.semen

	streamWriteUInt8(streamId, semen.country)
	streamWriteString(streamId, semen.farmId)
	streamWriteString(streamId, semen.uniqueId)
	streamWriteString(streamId, semen.name or "")
	streamWriteUInt8(streamId, semen.typeIndex)
	streamWriteUInt8(streamId, semen.subTypeIndex)
	streamWriteFloat32(streamId, semen.success)

	streamWriteFloat32(streamId, semen.genetics.metabolism)
	streamWriteFloat32(streamId, semen.genetics.fertility)
	streamWriteFloat32(streamId, semen.genetics.health)
	streamWriteFloat32(streamId, semen.genetics.quality)
	streamWriteFloat32(streamId, semen.genetics.productivity or -1)

end


--- Execute the event on the receiver.
---
--- Pattern A flow (caller-mutates-first + rebroadcast-from-run + ignoreConnection=sender):
---   * Caller (HandToolAIStraw:onInseminate) calls animal:setInsemination locally BEFORE sendEvent.
---   * Server branch (`not connection:getIsServer()`): apply mutation (idempotent),
---     then rebroadcast to other clients with ignoreConnection=sender.
---   * Client branch (`connection:getIsServer()`): apply mutation locally, no rebroadcast.
---
--- No dewar decrement happens here - this event is the hand-tool path; the straw
--- was already drained from its dewar when the hand-tool was filled, and the
--- hand-tool itself is consumed via markHandToolForDeletion.
---@param connection table Network connection the event arrived on
function AnimalInseminationEvent:run(connection)

	RmSafeUtils.safeCall("AnimalInseminationEvent:run", function()

		local clusterSystem = self.object:getClusterSystem()
		local identifiers = self.animal

		local animal = RLAnimalUtil.find(clusterSystem.animals, identifiers.farmId, identifiers.uniqueId, identifiers.country or identifiers.birthday.country)
		local isServerBranch = not connection:getIsServer()
		Log:trace("InseminationEvent:run branch=%s animal=%s", isServerBranch and "server" or "client", tostring(identifiers.uniqueId))

		if isServerBranch then
			-- Server: validate animal lookup, idempotency guard, then rebroadcast.
			-- Gate the rebroadcast on animal-found: if the authoritative server
			-- has no record of the animal, do NOT propagate to other clients.
			-- Unlike AIAnimalInseminationEvent (where the dewar straw is still
			-- spent on uniqueId match), this event has no compensating mutation.
			-- Rebroadcasting on miss would let non-sender clients apply locally
			-- even though server state is unchanged, producing divergence that
			-- the next dirty-sync from the server would correct backwards.
			if animal == nil then
				Log:warning("InseminationEvent:run animal not found uniqueId=%s, NOT rebroadcasting (server-authoritative reject)",
					tostring(identifiers.uniqueId))
				return
			end

			local canInseminate, reason = animal:getCanBeInseminatedByAnimal(self.semen)
			if not canInseminate then
				-- The hand-tool UI checks this first, but the event can arrive late
				-- or be crafted by a client. The server is therefore the final
				-- authority for the current pedigree policy.
				Log:info("InseminationEvent:run rejected uniqueId=%s reason=%s",
					tostring(identifiers.uniqueId), tostring(reason))
				return
			elseif animal.isInseminated then
				Log:debug("InseminationEvent:run skipping (already inseminated) uniqueId=%s",
					tostring(identifiers.uniqueId))
			else
				animal:setInsemination(self.semen)
				Log:info("InseminationEvent:run applied uniqueId=%s",
					tostring(identifiers.uniqueId))
			end

			-- Rebroadcast to other clients excluding sender (Pattern A).
			-- Sender mutated locally before sendEvent and must not receive an echo.
			g_server:broadcastEvent(
				AnimalInseminationEvent.new(self.object, self.animal, self.semen),
				nil, connection, nil)
			Log:trace("InseminationEvent:run rebroadcast ignoreConnection=sender uniqueId=%s",
				tostring(identifiers.uniqueId))
		else
			-- Client (rebroadcast from server): apply mutation locally.
			if animal ~= nil and not animal.isInseminated then
				animal:setInsemination(self.semen)
				Log:debug("InseminationEvent:run client-applied uniqueId=%s",
					tostring(identifiers.uniqueId))
			else
				Log:trace("InseminationEvent:run client-skip animal=%s inseminated=%s",
					tostring(animal), tostring(animal and animal.isInseminated))
			end
		end

	end)

end
