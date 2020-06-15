*短期事件研究法
*三个假设：
*金融市场是有效的，即股票价格反映所有的已知的公共信息，其次所研究的事件是市场未预期到的，因此这种异常收益可以度量股价对事件发生或信息纰漏异常反应的程度，在事件发生的窗口期无其他事件的混合效应。
// 短期事件包括发布应于公告，可以度量监管政策的影响。


*4. 短期事件研究法的Stata命令之 estudy 应用

*4.1 estudy的简介与基本语法


*estudy 是由 LIUC Università Carlo Cattaneo 的三位作者贡献的 Stata 外部命令，它作为一个集成的事件研究法估计程序，简洁清晰，方便使用，主要用于分析已知发生日期的某一特定事件或公告消息对公司股价的影响。但是，也因为 estudy程序的执行简单方便，导致了它只能分析单一确定事件对公司股价的影响而无法对不同时间段发生的多次事件 (如一年中公司发布两次甚至两次以上的并购公告) 进行分析。在运用 estudy 命令进行短期事件研究前，可通过在 Stata 命令对话框输入 findit estudy 查找到同名安装包与示例数据 data_estudy.dta 进行命令安装与数据试运行， estudy 命令的基本语法如下所示：


findit estudy

help estudy

estudy varlist1 [(varlist2) ... (varlistN)], datevar(varname)  ///
       evdate(date) dateformat(string) lb1(#) ub1(#) ///
           [options]

/*
estudy 命令的简单解释：

varlist1 [ (varlist2) ... (varlistN) ] ：每个varlist中填入的是样本内某一公司的变量存储名，变量中存放的是该公司的历史股票收益率时间序列数据。estudy 将区分不同的 varlist (公司变量名) ,分别汇报累积异常收益率 (CAR) 与平均累积异常收益率 (CAAR) 。
datevar : 定义日期变量 (date) ，设为时间格式。
evdate : 定义事件发生的日期，如07092015。
dateformat : 定义 evdate 中 “年月日” 的格式，比如 dateformat (MDY) 则表示事件的日期格式按照月份(M)、日(D)、年(Y)的顺序进行排列。
lb1(#) 和 ub1(#) 分别表示事件窗口期的起点  和终点  。例如，设定 lb1(-3) 与 ub1(2) 代表，从事件发生前三天起，到事件发生后两天止是事件窗口期，即计算  , 。可根据研究目的设置多个时间窗口期，通过改变事件窗口的起点和终点 lb2(#) 和 ub2(#) 来完成设置。

其他 options 设置：

eswlbound(#) : 设定估计窗口的起始日期，如有缺省，则自动设定第一个交易日为估计窗口的起始日期。
eswubound(#) : 设定估计窗口的截止日期，如有缺省，则自动设定事件发生日前一个月的30日为估计窗口的截止日期。
modtype ：设置估计股票正常收益率的估计模型。其中， modtype(SIM) 表示使用市场模型， modtype(MAM) 表示使用市场调整模型， modtype(MFM) 表示多因素模型， modtype(HMM) 表示历史平均模型。
indexlist(varlist) : 用于存放用于估计股票正常收益率的各因子。
diagnosticsstat(string) : 设定检验显著性的方法。可选择的有参数法 diagnosticsstat(Norm) 、 diagnosticsstat(Patell) 、 diagnosticsstat(ADJPatell) 、 diagnosticsstat(BMP) 、 diagnosticsstat(KP) 、 diagnosticsstat(KP) 以及非参数法 diagnosticsstat(Wilcoxon) 、diagnosticsstat(GRANK)。显著性检验方法具体说明可在Stata命令窗口输入 help estudy 了解更多。
estudy还有多个设置结果输出的选项，例如 suppress(string) 、 decimal(#) 等。suppress(group)表示报告每家公司的CAR, suppress(ind)表示报告整体CAAR。decimal可设置保留的小数点精确位数。
*/


*4.2 estudy命令实战

*在确认给 Stata 13.0 及以上版本的 Stata 安装好 estudy 安装包与示例数据 data_estudy.dta 之后，我们首先通过 cd 命令将当前工作路径所在的文件夹设置为保存示例数据的文件夹以方便调用(当然，也可以通过菜单操作找到数据存放的文件夹直接打开数据) 。示例数据 data_estudy.dta 内储存的是 IBM 与可口可乐等公司的日度股票时间序列数据，并假设有且仅有一确定事件于2015年7月9日发生，研究这一事件对所有样本内公司股票收益率的影响。接下来，利用 estudy 命令，我们可以方便地按照以下步骤进行短期事件研究分析：

*1).打开数据

use "data_estudy.dta", clear


*2).利用市场模型估计正常收益率，并以(-1,1)以及(-3,3)  为事件窗口期，同时计算多家公司两个事件窗口期的累积异常收益率与平均累积异常收益率，精确到小数点后四位数，可运行以下语句：
estudy boa ford boeing (apple netflix amazon facebook google),  ///
       datevar(date) evdate(07092015) dateformat(MDY)  ///
           lb1(-1) ub1(1) lb2(-3) ub2(3) ///
           indexlist(mkt) decimal(4)

*3).利用Fama三因子模型估计正常收益率，并以(-1,1)  、(-3,3)  、(-1,0)  以及 (0,3) 为事件窗口期，同时计算多家公司四个时间窗口期的累积异常收益率与平均累积异常收益率，并使用 Kolari 和 Pynnonen (2010) 的方法检验显著性，可运行以下语句：           
           
estudy boa ford boeing (apple netflix amazon facebook google) (boa ford boeing apple netflix amazon facebook google), datevar(date) evdate(07092015) dateformat(MDY) lb1(-1) ub1(1) lb2(-3) ub2(3) lb3(-1) ub3(0) lb4(0) ub4(3) modtype(MFM) indexlist(mkt smb hml) diagnosticsstat(KP)

*4).利用历史均值模型估计正常收益率，并以(-1,1)  、(-3,3)  以及(-1,0) 为事件窗口期，同时计算多家公司三个时间窗口期的累积异常收益率与平均累积异常收益率，并使用 Wilcoxon (1945) 的正负秩检验方法检验显著性。输出表将显示p值，而不是显着性星号，可运行以下语句：

estudy boa ford boeing (apple netflix amazon facebook google) (boa ford boeing apple netflix amazon facebook google), datevar(date) evdate(09072015) dateformat(DMY) lb1(-1) ub1(1) lb2(-3) ub2(3) lb3(-1) ub3(0) modtype(HMM) diagnosticsstat(Wilcoxon) showpvalues nostar


*5).利用市场模型估计正常收益率，并以 (-1,1)以及 (-3,3) 为事件窗口期，同时计算多家公司两个事件窗口期的累积异常收益率与平均累积异常收益率，将结果存储在 my_output_tables.xlsx 和 my_ar_dataset.dta 文件中，可运行以下语句：

estudy boa ford boeing (apple netflix amazon facebook google), ///
       datevar(date) evdate(07092015) dateformat(MDY)          ///
           lb1(-1) ub1(1) lb2(-3) ub2(3)  ///
           indexlist(mkt) outputfile(my_output_tables)
           
           
*结论:
*--运行以上命令之后，Stata会展示每个不同的事件窗口期的累积异常收益率与平均累积异常收益率的值及其显著性，通过正负符号及显著性分析，我们可以判断某一特定事件对不同公司价值的影响。           