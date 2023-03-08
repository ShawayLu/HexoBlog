---
title: c++的RAII技术
toc: true
date: 2023-03-08 09:14:43
updated: 2023-03-08 09:14:43
excerpt: c++的RAII技术
cover: /images/cover/6400.png
thumbnail: /images/cover/6400.png
categories:
- C/C++
tags:
- C/C++
---

**RAII**，全称**资源获取即初始化**（英语：**R**esource **A**cquisition **I**s **I**nitialization），它是在一些[面向对象语言](https://zh.wikipedia.org/wiki/面向对象语言)中的一种[惯用法](https://zh.wikipedia.org/w/index.php?title=慣用法&action=edit&redlink=1)。RAII源于[C++](https://zh.wikipedia.org/wiki/C%2B%2B)，在[Java](https://zh.wikipedia.org/wiki/Java)，[C#](https://zh.wikipedia.org/wiki/C♯)，[D](https://zh.wikipedia.org/wiki/D语言)，[Ada](https://zh.wikipedia.org/wiki/Ada)，[Vala](https://zh.wikipedia.org/wiki/Vala)和[Rust](https://zh.wikipedia.org/wiki/Rust)中也有应用。1984-1989年期间，[比雅尼·斯特劳斯特鲁普](https://zh.wikipedia.org/wiki/比雅尼·斯特勞斯特魯普)和[安德鲁·柯尼希](https://zh.wikipedia.org/w/index.php?title=安德鲁·柯尼希&action=edit&redlink=1)在设计C++异常时，为解决[资源管理](https://zh.wikipedia.org/w/index.php?title=資源管理&action=edit&redlink=1)时的[异常安全](https://zh.wikipedia.org/w/index.php?title=異常安全&action=edit&redlink=1)性而使用了该用法[[1\]](https://zh.wikipedia.org/zh-cn/RAII#cite_note-1)，后来[比雅尼·斯特劳斯特鲁普](https://zh.wikipedia.org/wiki/比雅尼·斯特勞斯特魯普)将其称为RAII[[2\]](https://zh.wikipedia.org/zh-cn/RAII#cite_note-FOOTNOTEStroustrup1994chpt._16.5_Resource_Management-2)。

RAII就自己的理解来说就是把两个成对的操作绑定到一个对象的生命周期上，对象构造时执行操作1，对象析构时执行操作2，这样一来不管是正常退出还是异常退出都能保证两个成对的操作都会被执行从而让代码更加安全。

c++中的**lock_guard**就使用了RAII:

```c++
template <class Mutex> class lock_guard {
private:
    Mutex& mutex_;

public:
    lock_guard(Mutex& mutex) : mutex_(mutex) { mutex_.lock(); }
    ~lock_guard() { mutex_.unlock(); }

    lock_guard(lock_guard const&) = delete;
    lock_guard& operator=(lock_guard const&) = delete;
};
```

使用:

```
extern void unsafe_code();  // 可能抛出异常

using std::mutex;
using std::lock_guard;

mutex g_mutex;

void access_critical_section()
{
    lock_guard<mutex> lock(g_mutex);
    unsafe_code();
}
```
