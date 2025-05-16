# BlackDuck Tests

这个目录包含 BlackDuck 应用程序的单元测试。

## 在 Xcode 中添加测试目标

由于我们是手动创建测试文件的，您需要在 Xcode 中添加测试目标：

1. 打开 BlackDuck.xcodeproj 文件
2. 在 Xcode 中，选择 File > New > Target...
3. 选择 "Unit Testing Bundle"
4. 将目标命名为 "BlackDuckTests"
5. 确保 "Target to be Tested" 设置为 "BlackDuck"
6. 点击 "Finish" 创建测试目标

## 添加现有测试文件

创建测试目标后，您需要将现有测试文件添加到项目中：

1. 在 Xcode 的项目导航器中，右键点击 "BlackDuckTests" 目标
2. 选择 "Add Files to 'BlackDuckTests'..."
3. 导航到 BlackDuckTests 目录
4. 选择所有测试文件（.swift 文件）
5. 确保 "Copy items if needed" 选项未选中
6. 确保 "Add to targets" 中选择了 "BlackDuckTests"
7. 点击 "Add" 添加文件

## 运行测试

添加测试文件后，您可以运行测试：

1. 选择 Product > Test 或使用快捷键 Cmd+U
2. 在测试导航器中查看测试结果

## 测试文件结构

- **Models/**
  - `FeedModelTests.swift` - 测试 Feed 和 FeedItem 模型
- **Managers/**
  - `FeedManagerTests.swift` - 测试 FeedManager 类
- **Utilities/**
  - `WebContentParserTests.swift` - 测试 WebContentParser 类

## 测试覆盖范围

当前测试覆盖以下功能：

1. **Feed 模型**
   - 基本属性和初始化
   - 未读计数功能
   - 相等性比较

2. **FeedItem 模型**
   - 基本属性和初始化
   - 日期格式化
   - 今日项目检测
   - 相等性比较

3. **FeedManager**
   - 添加和删除 Feed
   - 标记项目为已读/未读
   - 切换星标状态
   - 将所有项目标记为已读
   - 类别管理

4. **WebContentParser**
   - RSS Feed 解析
   - HTML 实体处理
   - 图片提取
   - 替代链接格式
   - 替代日期格式

## 扩展测试

您可以通过以下方式扩展测试：

1. 添加更多边缘情况测试
2. 添加性能测试
3. 添加 UI 测试
4. 实现模拟网络请求的测试
