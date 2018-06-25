SUDOA = '367690492' -- ایدی خود را وارد کنید
color = {
black = {30, 40},
yellow = {33, 43},
cyan = {36, 46}
}
redis = dofile('./libs/redis.lua')
function deleteMessages(chat_id, message_ids)
tdbot_function ({
_= "deleteMessages",
chat_id = chat_id,
message_ids = message_ids
}, dl_cb, nil)
end
function send(chat_id,msg,text)
assert( tdbot_function ({_ = "sendMessage",chat_id = chat_id,reply_to_message_id = msg,disable_notification = 0,from_background = 1,reply_markup = nil,input_message_content = {_ = "inputMessageText",text = text,disable_web_page_preview = 1,clear_draft = 0,parse_mode = html,entities = {}}}, dl_cb, nil))
end
function dl_cb(arg, data)
end
function run(msg,data)
if msg then
text = msg.content.text
if (msg.sender_user_id == tonumber(SUDOA)) then
if text == '/start' then
send(msg.chat_id,msg.id,'> ادمین گرامی به ربات ضد لاشی خود خوش امدید')
end
if text == 'reload' then
dofile('bot.lua')
send(msg.chat_id,msg.id,'> ربات بروز شد ')
end
if text and text:match('^set (.*)') then
local id = text:match('^set (.*)') 
redis:set('setchannel',id)
send(msg.chat_id,msg.id,'> کانال '..id..' اکنون از اسپم محافظت می شود')
end
if text and text:match('^time (%d+)') then
local id = text:match('^time (%d+)') 
redis:set('settime',id)
send(msg.chat_id,msg.id,'> تایم چک به '..id..' تغییر کرد')
end
if text and text:match('^pm (%d+)') then
local id = text:match('^pm (%d+)') 
redis:set('msgallowed',id)
send(msg.chat_id,msg.id,'> تعداد پیام های مجاز به '..id..' تغییر کرد')
end
if text == 'reopening' then
print('حفاظت کانال برداشته شد')
redis:del('allpm')
redis:del('lockchannel')
send(msg.chat_id,msg.id,'> کانال از حفاظت خارج شد')
end
if text == 'del all on' then
redis:del('delallpm')
send(msg.chat_id,msg.id,'> حذف کلی پیام های اخیر در تایم اسپم فعال شد')
end
if text == 'del all off' then
redis:set('delallpm','o')
send(msg.chat_id,msg.id,'>حذف کلی پیام های اخر در تایم اسپم خاموش شد')
end
if text == 'stats' then
local kos = 'ربات ضد اسپم چنل\n\n>کانال ذخیره شده :[ '..redis:get('setchannel')..' ]\n>تایم چک : [ '..redis:get('settime')..' ] \n پیام مجاز : [ '..redis:get('msgallowed')..' ]'
send(msg.chat_id,msg.id,kos)
end
if text == 'help' then
local kossher = [[

> reload
#بازنگری ربات

> set [ id channel ]
#تنظیم کانال خواهان محافظت

> time [ Time sec ]
#تنظیم تایم چک

> pm [ number en ]
#تنظیم حداکثر پیام مجاز

> reopening
#بازگشایی کانال قفل شده

> del all on
#حذف کلی پیام های ارسال در ان تایم

> del all off
#جهت خاموش کردن پاک کردن تمام پیام های اخیر در  زمان اسپم

> stats
#وضعیت ربات واطلاعات


by : @BlueAdmin

ch : @BlueAlireza
]]
send(msg.chat_id,msg.id,kossher)
end
end
if text == '/start' then
send(msg.chat_id,msg.id,'> لطفا در کانال @BlueAlireza عضو شوید')
end
if text then
print('\027[' ..color.yellow[2]..';'..color.black[1]..'m                     '..text..'                                \027[00m')  
print('\027[' ..color.cyan[2]..';'..color.black[1]..'m                      BY @ir_milad                                \027[00m')
end
if msg.content._ and not (msg.sender_user_id == tonumber(SUDOA)) then
if (msg.chat_id == redis:get('setchannel')) then
redis:sadd('allpm',msg.id)
print('\027['..color.yellow[2]..';'..color.black[1]..'m     یک پیام در کانال با ایدی '..msg.id..' ارسال شد      \027[00m')
end
end
if text and not (msg.sender_user_id == tonumber(SUDOA)) then
if (msg.chat_id == redis:get('setchannel')) then
local kos = redis:get('msgallowed') or 4
if (redis:scard('allpm') > tonumber(kos)) then
print(' کانال در حال اسپم است کانال تا اطلاع ثانویه قفل شد ')
send(SUDOA,0,'> کانال شما با شناسه '..msg.chat_id..' در حال اسپم خوردن است')
redis:set('lockchannel','ok')
end
end
end
if redis:get('lockchannel') and not redis:get('delallpm') then
if (msg.chat_id == redis:get('setchannel')) then
local list = redis:smembers('allpm')
for k,v in pairs(list) do
deleteMessages(msg.chat_id,{[0] =v})
end
end
end
if redis:get('lockchannel') then
if (msg.chat_id == redis:get('setchannel')) then
deleteMessages(msg.chat_id,{[0] =msg.id})
end
end
if not redis:get('timecheck') then
redis:del('allpm')
local kir = redis:get('settime') or 60
redis:setex('timecheck',tonumber(kir),true)
print('\027[' ..color.yellow[2]..';'..color.black[1]..'m                      باز شماری  پیام ها                                \027[00m')
end
end
end
function tdbot_update_callback(data)
if (data._ == "updateNewMessage") or (data._ == "updateNewChannelMessage") then
run(data.message,data)
elseif (data._== "updateMessageEdited") then
run(data.message,data)
data = data
local function edit(extra,result,success)
run(result,data)
end
assert (tdbot_function ({_ = "getMessage", chat_id = data.chat_id,message_id = data.message_id }, edit, nil))
assert (tdbot_function ({_="getChats",offset_order="9223372036854775807",offset_chat_id=0,limit=20}, dl_cb, nil))
end
end
