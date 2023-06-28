---
title: c++中的const和constexpr
toc: true
date: 2023-06-27 15:00:12
updated: 2023-06-27 15:00:12
excerpt: c++中的const和constexpr
cover: /images/cover/246223.jpg
thumbnail: /images/cover/246223.jpg
categories:
- C/C++
tags:
- C/C++
---

const的基础用法不多赘述，记录一下其他的点

### 1.const变量的跨文件使用

const 对象被设定为仅在文件内有效。当多个文件中出现了同名的 const 变量时，其实等同于**在不同文件中分别定义了独立的变量**。

例如有以下三个文件

test1.h

```c++
int getRandom();
void fun();

const int r = getRandom();

```

test1.cpp

```c++
#include <iostream>
#include "test1.h"

int getRandom()
{
    /*生成随机数并返回*/
}

void fun()
{
    std::cout<<r<<std::endl;
}

```

main.cpp

```c++
#include <iostream>
#include "test1.h"

int main()
{
    std::cout<<r<<std::endl;
    fun();
    return 0;
}

```

其运行结果输出的两个数字是不一样的。

如果想要多个文件共享同一个const变量，我们可以把const变量的声明和定义分开，并且在声明的时候加上extern关键字，例如

test1.h

```c++
int getRandom();
void fun();

extern const int r;

```

test1.cpp

```c++
#include <iostream>
#include "test1.h"

const int r = getRandom();

int getRandom()
{
    /*生成随机数并返回*/
}

void fun()
{
    std::cout<<r<<std::endl;
}

```

main.cpp

```c++
#include <iostream>
#include "test1.h"

int main()
{
    std::cout<<r<<std::endl;
    fun();
    return 0;
}

```

### 2.顶层/底层const

顶层const：意思是指针/变量本身是个常量

底层const：意思是指针所指向的对象是个常量

```c++
int i = 0;
const int* p1 = &i; //底层const,也可以写成int const* p1 = &i;
int* const p2 = &i; //顶层const
const int ci = 42; //顶层const
```

### 3.constexpr

constexpr指的是值不会改变并且在编译阶段就能计算出来结果的表达式，它和const的区别是const强调不可修改，constexpr强调在编译器就可以计算出来结果并且不可改变。

代码如下：

```c++
int main() {
    const int val = 1 + 2;
    return 0;
}
```

上面的这份代码编译后会把3直接赋值给val，可以看的出来3是在编译期间求出来的值

```c++
int Add(const int a, const int b) {
    return a + b;
}

int main() {
    const int val = Add(1, 2);
    return 0;
}
```

这份代码在编译期间就没有进行求值，而是运行期间进行了求值

```c++
int main() {
    constexpr int val = 1 + 2;
    return 0;
}
```

这份代码在编译后的结果和第一份代码的编译结果一摸一样，说明constexpr和const一样可以在编译期间求值

```c++
constexpr int Add(const int a, const int b) {
    return a + b;
}

int main() {
    const int val = Add(1, 2);
    return 0;
}
```

这份代码在第二份的代码上做了优化，用constexpr去修饰函数，使其可以在编译期间求值

```c++
constexpr int Add(const int a, const int b) {
    return a + b;
}

int main() {
    const int val = Add(1, 2);
    int val1 = 3;
    int val2 = Add(val, val1);
    return 0;
}
```

在这份代码中val在编译期间求值，而val2在运行期间求值，因为其引入了非const变量val1

通过本示例，可以看出，将函数声明为`constexpr`可以提示效率，让编译器来决定是在编译阶段还是运行阶段来进行求值
