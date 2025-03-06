---
title: c++右值引用和std::move
toc: true
date: 2023-06-30 10:39:49
updated: 2023-06-30 10:39:49
excerpt: c++右值引用和std::move
cover: /images/cover/1050187.jpg
thumbnail: /images/cover/1050187.jpg
categories:
- C/C++
tags:
- C/C++
---

### **什么是左值、右值**

左值**可以取地址、位于等号左边**；而右值**没法取地址，位于等号右边**。

### **什么是左值引用、右值引用**

#### 左值引用

左值引用就是指向左值的引用，左值引用不能指向右值

```c++
int a = 0;
int& b = a; //b是一个左值引用
int& c = 6; //编译错误，因为6是一个右值，左值引用不能绑定在右值上
```

左值引用不能指向右值，因为左值引用允许修改被引用变量的值，但是右值没有地址，无法修改

const左值引用可以指向右值，因为const左值引用无法修改指向对象的值，所以STL许多函数的参数都是const type&

#### 右值引用

右值引用就是可以指向右值的引用，右值引用不能指向左值

```c++
int&& a = 6;//a是一个右值引用
int b = 5;
int&& c = b;//错误，b是一个左值
a = 7;//右值引用允许修改右值
```

### std::move函数

std::move函数是将一个左值转换成右值，函数本身和移动没有关系，仅仅是把左值转换成了右值

```c++
int a = 6;
int& b = a;
int&& c = std::move(a);//通过std::move把一个左值转换成了右值
```

因为std::move的作用仅仅是转换，所以性能上不会有任何提升

### 右值引用本身是左值还是右值

先说结论：被**声明出来的，有名称的右值引用**其本身就是左值，因为其有地址，其他的是右值。也可以说**作为函数返回值的 && 是右值，直接声明出来的 && 是左值**。

```c++
void fun(int&& n)
{
    n = 1;
}

int main()
{
    int a = 5;
    int& b = a;
    int&& c = std::move(a);
    
    fun(a);//错误，a是一个左值
    fun(b);//错误，b是一个左值引用
    fun(c);//错误，c本身是一个左值
    
    fun(std::move(a));//正确
    fun(std::move(b));//正确
    fun(std::move(c));//正确
    fun(6);//正确
}

```

### std::move函数的应用场景

std::move函数是将一个左值转换成右值，仅仅有转换功能，函数本身和移动没有关系，因此std::move函数本身并不能提高性能，需要配合**移动构造函数**或**移动赋值函数**来实现移动语义从而避免产生深拷贝来提升性能。

因此std::move可以在对象**需要拷贝且被拷贝者之后不再被需要**的这种情况下提升性能

例如有如下类

```c++
class Obj
{
public:
    //默认构造函数
    Obj()
    {
        mem = nullptr;
        len = 0;
    }
    //构造函数
    Obj(size_t len)
    {
        this->len = len;
        mem = (char*)(malloc(len));
        memset(mem, 1, len);
    }
    //析构函数
    ~Obj()
    {
        if(mem)
            free(mem);
    }
    //拷贝构造函数
    Obj(const Obj& other)
    {
        len = other.len;
        mem = nullptr;
        if(len > 0)
        {
            mem = (char*)(malloc(len));
            memcpy(mem, other.mem, other.len);
        }
    }
    //拷贝赋值函数
    Obj& operator =(const Obj& other)
    {
        if(mem)
            free(mem);
        len = other.len;
        mem = nullptr;
        if(len > 0)
        {
            mem = (char*)(malloc(len));
            memcpy(mem, other.mem, other.len);
        }
        return *this;
    }
    //移动构造函数
    Obj(Obj&& other)
    {
        len = other.len;
        mem = other.mem;
        other.len = 0;
        other.mem = nullptr;
    }
    //移动赋值函数
    Obj& operator =(Obj&& other)
    {
        len = other.len;
        mem = other.mem;
        other.len = 0;
        other.mem = nullptr;
        return *this;
    }
private:
    char* mem;
    size_t len;
};

```

类中维护了一段内存，如果调用**拷贝构造和拷贝赋值就会重新申请内存并写入数据**，如果调用**移动构造和移动赋值就仅会把mem的所有权给移动一下**。相比之下移动构造和移动赋值函数的性能是比拷贝构造和拷贝复制的性能要高的。但是有一点要记住就是**被移动的对象再移动完之后内部的资源都会被清空**。

例如有以下调用函数

```c++
int main()
{
    int allCount = 1000000;
    size_t perSize = 10;
    std::vector<Obj> v;
    v.reserve(allCount);

    v.resize(0);
    auto start = std::clock();
    for(size_t i = 0; i < allCount; i++)
    {
        Obj obj(perSize);
        v.push_back(obj);
    }
    printf("push_back time:%lfs\n", ((double)(std::clock()-start))/CLOCKS_PER_SEC);

    v.resize(0);
    start = std::clock();
    for(size_t i = 0; i < allCount; i++)
    {
        Obj obj(perSize);
        v.push_back(std::move(obj));
    }
    printf("move push_back time:%lfs\n", ((double)(std::clock()-start))/CLOCKS_PER_SEC);

    return 0;    
}
```

第一个循环用了普通的push_back会调用拷贝构造函数，第二个循环先用std::move把左值转换成右值然后再调用push_back函数就会调用移动构造函数，但是每个循环内部的obj在push_back后其中的数据也被清空了。经过实现第二个循环的效率比第一个循环要高。

上述代码在Compiler Explorer的运行:

<iframe width="800px" height="200px" src="https://godbolt.org/e#z:OYLghAFBqd5QCxAYwPYBMCmBRdBLAF1QCcAaPECAMzwBtMA7AQwFtMQByARg9KtQYEAysib0QXACx8BBAKoBnTAAUAHpwAMvAFYTStJg1DIApACYAQuYukl9ZATwDKjdAGFUtAK4sGIAMxcpK4AMngMmAByPgBGmMQgABzSAA6oCoRODB7evgFBaRmOAmER0SxxCcm2mPbFDEIETMQEOT5%2BgTV1WY3NBKVRsfFJ0gpNLW15nWN9A%2BWVIwCUtqhexMjsHOb%2B4cjeWADUJv5uyGPotHgxx9gmGgCC27v7mEcnZwTE4cA3d49mOwYey8h2Op3OTl%2BDyeQJeb1OjjYUP%2BgOBoJOADdMA4SMi/nsmAoFAcAPIxbR/EwAdisDxSXhil2QID%2BBzZBwA9ByTNgAJwmCxWXmJHki%2B63e6SHkANhMvNuyR5/MSGhM91V2AArCZElSBQARGVy7UWVUPdmk8kQRas9nU2n3C0WtgsN76g4MLy0WgpT7HB1O9n0Bhug6q/wBu1Uw3m9lco3ynVSvk61Xqnna3UGhMms2O9lk7QQDIAL0wAH0CAdgzbY2z7bbAwQEHgFABaG7B0PB/2Np0u0MQZAIZoAKkWEBYYloqGQEBrNojfedmBYSgIk9XpAOQWrjEXkfr0b78ewssTvI154VyczeoshrPxoFeYtAD9C9a%2Bw26068FRNxYWt80DC0qGITBMEAg9v2PX9T1lRIrAsPVsBFCwpV5R9ryTJVUzVDU72zJ9eVzPtPzQBgxktCkzGlA5UGbeJgItH8QKdLtjndRiEHiAA6Hsl1/FdXS4j0vR9P0hPYi1/3nRg3mwMMWNAtjQP7VdB2HMcJynb1Z3khhFhg4TQJdZAUgAT0A7ceP4l1bKY4gBP3XtTKPGN2OpTyLQQnVkNQ9DMMfdDMysLV8IsNwMx1e9sOfU1yPJcx6NQFJ4iYIhiDdIcBGowsUoYpyVKPQ8/wAl0SvUg5wMg6C3JkoMFLEuznMEsqRNDT1vV9YgGvUuTOP8JSNCq1iaWXMzNLEocR2IcdJ2nAyF366q2XMqybKK3jnIc7b%2BJrVbA28ya2Qggg1hDUdm1bI6jjg9jTz1e573CzNHnuEUSJvPCVQImKswfHMXySosCrowrWqqtTQKG7inJchg7s6lqEZdZH2VaxHQ3DDrMbR6b/HdbrJL66Txp8uNuWwZ7XoBj6vtC/yAdVKKAbi4HEt/cHUvS4hMpIHKech4rYLxtk4f2trGAx9bCfhna%2BPR8nQKxyXcdOqWlfl8Seqk8WDnOy6DmulsFDuk66S%2BDFMvYPttPmg5lbK0sKyrdrKWPaS/nCKsp3CL9oQm39fYOacPC8QRQy4DRY7ju7XcrA4%2BaEPAy2jjXf3OEAQCxHEybcArhoODE7oxPiIKUYgsQgcPVkEEzHl/cvK7TqDRrupgvCIA4ZhaUNs5QGdkAAay/FW2X4YhizbpO8Bx/0DnnsEw%2B9CPBEXvBrGsaHg8atlCwYq0U7bxv1PL%2BkFAQcsYiYUeIFQckz6jSm2RSL5BAA8wzEv6/b9Hg4iI7ZmE1LQKg5tNRuCRmYMw24oDoFWIyTAE5B57FnGPRYbY%2B4EGMhyNwIQSRuAANJCHLMobAAAlcsQhsBuEbn2FumBXYQA7hPXu4wqxiVQcPDBd0p4zzLHPBeEYl7wlXrQdeBBN7b0sLvA2h9H5FhPmWZ%2BgYL5eCvjfO%2BY9B4sFQDXRRxkLYPQtO/X2X8YF6KxMnDRf9tGALwGwFkICwEQKgd/OBEAEEMnoCggg6Ac5oPvpg7BuD8GEJIWQyh1DaH0N/EbYgIZcasSDp5DgyxaCcE1LwPwHAtCkFQJwaKlhrC91WOsV42weCkAIJodJywR4gE1P4PiZheRmEkLyaUXAqRcE1FwaUGhEj6E4JIHJdSCmcF4AoEAGgal1OWHAWASBMCqGxN3Eg5BKDNGAAoZQhhahCAQKgAA7rk6paAWApDoJlLI%2ByIi0COac3J%2BTLnXPoAkFg3wTnSkkOWLwyAWjlgJEYcsAyNCwLeXQeIkRWCbF4FCj5JJu5PLORM1Z2J7jEF2VM4IazkCNHwLk3g/BBAiDEOwKQMhBCKBUOoPJOgQCwIMEYFAMibCXBiDMyAyw0r1BmRwXg%2Bj4hfCwNy60Kw1gbD0BCBg9zDnHLRdwXgJz%2BYpE4DwDJWTxkMsmRwbA%2BKNnZQALLhAAOIAHUDgguADuaUfENCtIOBAYpVhLDblwIQQWVTFi8FqQyxZKzDVZS2bXbFeyDmPMVechFqArk3PqPKqNzyJmIuGF8owPy/kAqBcAZAyAwUwLmWm4gsKnGCtICW5Fwho3ovxVinFFaMUEv8eEXFpLhCiHEFSjttK1ATN0EEFlxh2X6CuOK3lvosgCqFViYgoqmHwGWAocp0qgiyqTaimNpBVVMHVcqrVHBsmkBeUKzgBr1lZQOKahglqDh5uQDuMwrSHXOtddYD1%2BAr0%2Br9Qs5YvEmBYASBKxpkh7VUg0FSTUGh/CJDMMkRI/h2kjI4GMk9EzCkVpmXM/1WhjIobMDq/JmHf0BuWHOjIzhJBAA%3D%3D"></iframe>

还有一些对象是只允许移动不允许拷贝的，比如**unique_ptr**，这种对象只允许移动内部资源所有权



### **完美转发std::forward**

std::forward与std::move一样也是类型转换，但是std::move只能转出来右值，而std::forward可以转出来左值或右值

std::forward<T>(u)有两个参数：T与 u。 1. 当T为左值引用类型时，u将被转换为T类型的左值； 2. 否则u将被转换为T类型右值。

```c++
void fun1(int&& n)
{
    n = 2;
}

void fun2(int& n)
{
    n = 2;
}

int main()
{
    int n = 0;
    int&& nr = std::move(n);
    fun1(nr);//错误 nr是一个左值
    fun1(std::move(nr));//正确 转换成了右值
    fun1(std::forward<int>(nr));//正确 转换成了右值
    
    fun2(nr);//正确 nr是一个左值
    fun2(std::move(nr));//错误 左值引用无法绑定到右值上
    fun2(std::forward<int&>(nr));//正确 转换成了左值引用
    
    return 0;
}

```

