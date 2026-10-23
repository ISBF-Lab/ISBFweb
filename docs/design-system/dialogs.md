# 前台弹窗开发规范

用户于2026-10-20指定“更改个人资料照片”截图，并确认统一前台对话框外框与按钮、手机留边，以及共享样式和CI检查。实际截图、源码与验证边界见[本轮记录](reviews/dialog-consistency-20261020/README.md)。

## 默认做法

任务弹窗使用UI kit的`DModal`，确认、删除和提示使用`dialog`服务。操作使用`DButton`，表单使用`Form`公开API。共享外观由主题的`dialog-consistency.scss`负责，服务调用、组件直接渲染和插件弹窗均自动适用，不需要登记路由或增加组件名单。

- 外框：`--isbf-v2-radius-md`（16px）、1px语义边框、surface背景、text前景；不增加面板阴影。
- 标题、正文和底部：space-4（16px）内距，沿用分区细线。只对实际存在的区域应用，不制造空底部。
- 有文字的普通操作：pill圆角、至少44px高、font-sm/weight-medium；主动作accent/contrast，危险动作danger。保留loading、disabled、pressed和错误语义。关闭图标、工具栏、菜单项和选择器不是普通文字操作。
- 手机（≤600px）：四周至少space-4并计入设备安全区；保留四角圆角，正文独立滚动，底部操作可访问。继续使用DModal的键盘、焦点和关闭机制。
- 保留各业务原有宽度、桌面定位及`--large`/`--max`用途。内容区的表格、编辑器和横向滚动由业务组件负责；不能用整容器裁剪隐藏问题。

## 组件示例

```gjs
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import DModalCancel from "discourse/ui-kit/d-modal-cancel";
import { i18n } from "discourse-i18n";

export default <template>
  <DModal
    class="task-confirmation"
    @closeModal={{@closeModal}}
    @title={{i18n @model.titleKey}}
  >
    <:body><p>{{i18n @model.messageKey}}</p></:body>
    <:footer>
      <DButton
        class="btn-primary"
        @action={{@model.confirm}}
        @label={{@model.confirmKey}}
      />
      <DModalCancel @close={{@closeModal}} />
    </:footer>
  </DModal>
</template>
```

带表单的弹窗将`Form`放在body中。底部主动作通过唯一表单ID、`@form`和`@type="submit"`关联body中的Form，保留原生Enter提交并避免嵌套form或绕过FormKit校验。提交中禁止重复请求；需要保留草稿的任务通过`beforeClose`保护关闭。可参照实际的`ISBFCalendarEntryEditor`和`ISBFResourceDirectoryDialog`，不要复制其业务请求作为通用控件。

## 复用边界与例外

用户明确选择只改前台对话框。后台、用户卡、图片查看器、编辑器、手机菜单，以及独立`/join/`招募页保留各自规范。尤其注意：float-kit和聊天动作菜单会借用DModal，不能据DOM组件名把菜单改成表单弹窗。独立认证页的面板也不属于DModal外框。

[例外登记](dialog-exceptions.json)记录源码用途、选择器、来源和验证。平台已有样式作为基础行为及其他主题的回退保留；共享主题覆盖其弹窗外观。基础层登记精确到声明摘要，不代表批准其默认外观。特殊任务只复用有依据的布局差异，新增外观决定仍需人工确认并保存依据。

## 自动检查与评审

```bash
pnpm lint:dialogs
pnpm exec node --test script/check-isbf-dialogs.test.mjs
```

检查器流式扫描核心、主题、插件的前台源码，支持SCSS嵌套，并检查手写dialog、浏览器原生弹窗、DModal内联样式和公共层以外的外框/按钮声明。依赖、生成资源、后台和测试夹具不作为产品弹窗；单独批准的招募源码明确排除。符号链接源码会读取真实目标；读取失败会使检查失败。

新增例外必须提供具体原因、设计来源及验证入口。不要为消除报错而自动批量接受新规则；优先移除重复外观、复用共享组件。检查器是结构与源码门禁，实际渲染以QUnit计算样式、四种布局的系统检查和截图评审为准。

修改后验证电脑、手机、明暗、长文、失败重试、键盘和关闭行为；保留受影响的权限及保存测试。共享主机按[资源规范](resource-policy.md)串行使用工具，不启动完整预览论坛，不用生产数据做测试。
