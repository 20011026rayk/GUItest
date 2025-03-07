ImagePath.add(r"C:\wortools\auto_GT\code_files.sikuli")

Settings.ActionLogs = True
Settings.MinSimilarity = 0.7
Settings.MoveMouseDelay = 0.5
Settings.ObserveScanRate = 2.0
Settings.ObserveMinChangedPixels = 50

# 使用 SikuliX 打开应用程序
app_path = "C:\\workfiles\\ACC\\software\\V3.5_beta_20250116"
App.open(app_path)

# 添加powershell脚本监控整个过程软件的资源占比
run("powershell.exe -File C:\\worktools\\Auto_GT\\code_files.sikuli\\demo2.ps1")

if exists("1739843769668.png"):
    find ("1739843769668.png")
    doubleClick (Pattern("1739843769668.png").targetOffset(-82,-28))
    wait(2)
# 检查设备列表后选择设备开始接收
if exists("devices.png"):    
    click("devices.png")
    if exists("device_list.png"):
        click(Pattern("choose.png").targetOffset(11,12))
        print("设备已选择")
    else:
        print("检查截图")   

# 选择图像频率
click(Pattern("full_window.png").targetOffset(-256,0))  

# 确定图像频率
click("1739947019355.png")

# 开始接收数据
click(Pattern("receive_reset.png").targetOffset(-4,-8))

# 开始绘图
click(Pattern("full_window.png").targetOffset(-146,213))
wait(2)

# 保存图谱频率截图
from sikuli import Screen, Region
from java.io import File
from javax.imageio import ImageIO

screen = Screen()
region = Region(629,323,447,391)  # 使用英文括号
screenshot = screen.capture(region)
bufferedImage = screenshot.getImage()
file_path = r"shot.png"
ImageIO.write(bufferedImage, "png", File(file_path))
print("Screenshot saved to: " + file_path)