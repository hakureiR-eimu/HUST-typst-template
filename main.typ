#import "template.typ": *
#import "@preview/codelst:2.0.0": sourcecode

#show: project.with(
  anony: false,
  title: " ",
  author: "张钧玮",
  school: "计算机学院",
  group:"OmegaXYZ",
  id: "U202115520",
  mentor: "何云峰",
  class: "大数据2102班",
  date: (2023, 12, 10)
)

= 简答
== 问题1
1. 你选修计算机图形学课程，想得到的是什么知识？现在课程结束，对于所得的知识是否满意？如果不满意，你准备如何寻找自己需要的知识。
我选修图形学是想要了解图形学的基本知识，关于图形如何被CPU和GPU处理，是什么样格式的数据，有哪些处理办法。但是感觉课时太短，内容又太多，显得知识十分杂乱，没有明确的体系和脉络，掌握的不是很好，只能多去bilibili大学上网课了。
2. 你对计算机图形学课程中的哪一个部分的内容最感兴趣，请叙述一下，并谈谈你现在的认识。
我对图形的变换最感兴趣。现在我了解了很多旋转和线性代数之间的关系，比如二维的逆时针旋转90°就相当于矩阵乘以一个矩阵{(0,1),(-1,0)}，三维的旋转也是同理。通过一系列矩阵变换竟然就可以实现复杂的变换，这让我感到十分惊奇。
3. 你对计算机图形学课程的教学内容和教学方法有什么看法和建议。
加课时加学分，不要放到早八。

= 论述

选择A实验报告
= 课后作业

选择A日地月模型
== 实验内容

利用OpenGL框架，设计一个日地月运动模型动画，要求如下：
1. 运动关系正确，相对速度合理，且地球绕太阳，月亮绕地球的轨道不能在一个平面内。

2. 地球绕太阳，月亮绕地球可以使用简单圆或者椭圆轨道。

3. 对球体纹理的处理，至少地球应该有纹理贴图。
4. 增加光照处理，光源设在太阳上面。
5. 为了提高太阳的显示效果，可以在侧后增加一个专门照射太阳的灯。

== 实验方法和过程 

继承并且使用第二次作业的代码。实现了球体的绘制（事实上也实现了运动关系）。通过以下步骤逐步完成实验要求。
=== 添加运动关系

运动关系的思路在于正确地描述旋转矩阵。假设太阳位于中心，地球绕太阳旋转，这是矩阵1；月球绕地球转，这是矩阵2；月球的位置就在于矩阵1跟矩阵2。值得注意，结果还需要乘以一个旋转矩阵来模拟月球的偏转。下面给出旋转矩阵的关键代码：
#sourcecode(```cpp
//地球的旋转矩阵
vmath::mat4 trans2 = vmath::perspective(60, aspact, 1.0f, 500.0f) *vmath::translate(0.0f, 0.0f, -5.0f)
*vmath::rotate(xRot, vmath::vec3(0.0, 1.0, 0.0))
*vmath::translate(3.0f, 0.0f, 0.0f)
*vmath::scale(0.3f);
//月球的旋转矩阵
vmath::mat4 trans3 = vmath::perspective(60, aspact, 1.0f, 500.0f) *vmath::translate(0.0f, 0.0f, -5.0f)
*vmath::rotate(xRot, vmath::vec3(0.0, 1.0, 0.0))
*vmath::translate(3.0f, 0.0f, 0.0f)
*vmath::scale(0.3f)
*vmath::rotate(yRot, vmath::vec3(0.0, 0.0, 1.0))
*vmath::translate(3.0f, 0.0f, 0.0f)
*vmath::scale(0.3f);
```)通过以上旋转矩阵就可以轻松确认几个球体对象的位置，着色器附着上去就可以实现正确的运动关系了。
=== 添加纹理

添加纹理的思路在于正确地导入图片，然后绑定纹理对象。这里我使用了stb_image.h库文件，修改了着色器的设置，以下代码是关键代码：
#sourcecode(```cpp
    //导入处理图片的库文件
    #define STB_IMAGE_IMPLEMENTATION
    #include <stb_image.h>
    ........

    //声明所需的纹理对象的句柄
    GLuint texture_buffer_object_sun;	// 太阳纹理对象句柄
    GLuint texture_buffer_object_earth;	// 地球纹理对象句柄
    GLuint texture_buffer_object_moon;	// 月球纹理对象句柄
    int shader_program;				// 着色器程序句柄
    .........
    //对于球,生成顶点的时候需要增加生成纹理顶点
    sphereVertices.push_back(xSegment);
		sphereVertices.push_back(ySegment);

    .........
    // 创建纹理对象并加载纹理
    void loadTexture(GLuint& texture_buffer_object, const char* filename) {
      glGenTextures(1, &texture_buffer_object);
      glBindTexture(GL_TEXTURE_2D, texture_buffer_object);

      // 指定纹理的参数
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

      int width, height, nrchannels;
      stbi_set_flip_vertically_on_load(true);
      unsigned char* data = stbi_load(filename, &width, &height, &nrchannels, 0);

      if (data) {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);
      }
      else {
        std::cout << "Failed to load texture: " << filename << std::endl;
      }

      glBindTexture(GL_TEXTURE_2D, 0);
      stbi_image_free(data);
    }

    // 创建纹理对象并加载所有纹理
    void loadAllTextures() {
      loadTexture(texture_buffer_object_sun, "sun.jpg");
      loadTexture(texture_buffer_object_earth, "earth.jpg");
      loadTexture(texture_buffer_object_moon, "moon.jpg");
    }

    .........
    //绑定太阳纹理
		glUniform1i(glGetUniformLocation(shader_program, "tex"), 0);  

		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, texture_buffer_object_sun);

```)
=== 添加光源

修改shader增加光源相关属性然后增加法线信息输入从而在片段着色器里计算光源信息，以下是修改关键代码：
#sourcecode(```cpp
// shader
	// 顶点着色器和片段着色器源码
	const char* vertex_shader_source =
		"#version 330 core\n"
		"layout (location = 0) in vec3 vPos;\n"			// 位置变量的属性位置值为0
		"layout (location = 1) in vec2 vTexture;\n"		// 纹理变量的属性位置值为1
		"out vec4 vColor;\n"							// 输出4维颜色向量
		"out vec2 myTexture;\n"							// 输出2维纹理向量
		"out vec3 FragPos;\n"		
		"out vec3 Normal;\n"							// 光照
		"uniform mat4 transform;\n"
		"uniform vec4 color;\n"
		"uniform mat4 projection;\n"
		"void main()\n"
		"{\n"
		"    gl_Position = transform * vec4(vPos, 1.0);\n"
		"    vColor = color;\n"
		"    myTexture = vTexture;\n"
		"}\n\0";

	const char* fragment_shader_source =
		"#version 330 core\n"
		"in vec4 vColor;\n"			// 输入的颜色向量
		"in vec3 Normal;\n"			// 输入的法向量
		"in vec3 FragPos;\n"			// 输入的片段位置向量
		"in vec2 myTexture;\n"		// 输入的纹理向量
		"out vec4 FragColor;\n"		// 输出的颜色向量
		"uniform vec3 lightPos;\n"
		"uniform vec3 lightColor;\n"
		"uniform sampler2D tex;\n"
		"void main()\n"
		"{\n"
		"    FragColor = texture(tex, myTexture) * vColor;\n"	// 顶点颜色和纹理混合
		"}\n\0";

-------------------------------------------------

  //初始化光源
	vmath::vec3 lightPos(0.0f, 3.0f, 0.0f);
	glUniform3fv(glGetUniformLocation(shader_program, "lightPos"), 1, &lightPos[0]);

-------------------------------------------------
  //计算光照
  glUniform3fv(glGetUniformLocation(shaderProgram, "lightPos"), 1, glm::value_ptr(lightPos));
  glUniform3fv(glGetUniformLocation(shaderProgram, "lightColor"), 1, glm::value_ptr(lightColor));
```)
== 实验结果
#img(
  image("assets/Snipaste_2023-12-10_23-30-15.png"),
  caption:"日地月模型"
)
#img(
  image("assets/Snipaste_2023-12-10_23-30-52.png"),
  caption:"日地月模型"
)
运动关系和纹理都实现了，但是光照效果不是很好，具体原因不是很清楚，因为光源确实是存在效果的。
== 心得体会

课时太短然后因此实验和平时作业内容显得十分跳跃，很多重要的知识点和概念都没有来得及讲透学透。早八太困。
== 源代码

#sourcecode(```cpp
//////////////////////////////////////////////////////////////////////////////
//
//  Sphere.cpp
//  1. 球体的绘制（求出球面上所有的点）
//  2. 三角面片的构造
//  3. 利用统一变量进行数据传递
//////////////////////////////////////////////////////////////////////////////


#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <vmath.h>
#include <vector>
#include <Windows.h>

#define STB_IMAGE_IMPLEMENTATION
#include <stb_image.h>

// 窗口尺寸参数
const unsigned int SCR_WIDTH = 1200;
const unsigned int SCR_HEIGHT = 600;

// 旋转角度
static GLfloat aspect = 0.0;

// 旋转参数
const float fovy = 60;
float aspact = (float)SCR_WIDTH / (float)SCR_HEIGHT;
const float znear = 1;
const float zfar = 800;

// 句柄参数
GLuint vertex_array_object;		// VAO句柄
GLuint vertex_buffer_object;	// VBO句柄
GLuint element_buffer_object;	// EBO句柄
GLuint texture_buffer_object_sun;	// 太阳纹理对象句柄
GLuint texture_buffer_object_earth;	// 地球纹理对象句柄
GLuint texture_buffer_object_moon;	// 月球纹理对象句柄
int shader_program;				// 着色器程序句柄

// 球面顶点数据
std::vector<float> sphereVertices;
std::vector<int> sphereIndices;
const int Y_SEGMENTS = 20;
const int X_SEGMENTS = 20;
const float Radio = 2.0;
const GLfloat  PI = 3.14159265358979323846f;

// 生成球的顶点和纹理顶点
void generateBallVerticles(std::vector<float>& sphereVertices) {
	for (int y = 0; y <= Y_SEGMENTS; y++)
	{
		for (int x = 0; x <= X_SEGMENTS; x++)
		{
			float xSegment = (float)x / (float)X_SEGMENTS;
			float ySegment = (float)y / (float)Y_SEGMENTS;
			float xPos = std::cos(xSegment * Radio * PI) * std::sin(ySegment * PI);
			float yPos = std::cos(ySegment * PI);
			float zPos = std::sin(xSegment * Radio * PI) * std::sin(ySegment * PI);
			// 球的顶点
			sphereVertices.push_back(xPos);
			sphereVertices.push_back(yPos);
			sphereVertices.push_back(zPos);
			sphereVertices.push_back(xSegment);
			sphereVertices.push_back(ySegment);
		}
	}
}

// 生成球的顶点索引
void generateBallIndices(std::vector<int>& sphereIndices) {
	for (int i = 0; i < Y_SEGMENTS; i++)
	{
		for (int j = 0; j < X_SEGMENTS; j++)
		{
			sphereIndices.push_back(i * (X_SEGMENTS + 1) + j);
			sphereIndices.push_back((i + 1) * (X_SEGMENTS + 1) + j);
			sphereIndices.push_back((i + 1) * (X_SEGMENTS + 1) + j + 1);

			sphereIndices.push_back(i * (X_SEGMENTS + 1) + j);
			sphereIndices.push_back((i + 1) * (X_SEGMENTS + 1) + j + 1);
			sphereIndices.push_back(i * (X_SEGMENTS + 1) + j + 1);
		}
	}
}

// 创建纹理对象并加载纹理
void loadTexture(GLuint& texture_buffer_object, const char* filename) {
	glGenTextures(1, &texture_buffer_object);
	glBindTexture(GL_TEXTURE_2D, texture_buffer_object);

	// 指定纹理的参数
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

	int width, height, nrchannels;
	stbi_set_flip_vertically_on_load(true);
	unsigned char* data = stbi_load(filename, &width, &height, &nrchannels, 0);

	if (data) {
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
		glGenerateMipmap(GL_TEXTURE_2D);
	}
	else {
		std::cout << "Failed to load texture: " << filename << std::endl;
	}

	glBindTexture(GL_TEXTURE_2D, 0);
	stbi_image_free(data);
}

// 创建纹理对象并加载所有纹理
void loadAllTextures() {
	loadTexture(texture_buffer_object_sun, "sun.jpg");
	loadTexture(texture_buffer_object_earth, "earth.jpg");
	loadTexture(texture_buffer_object_moon, "moon.jpg");
}


// 编写并编译着色器程序
void editAndCompileShaderProgram() {
	// 顶点着色器和片段着色器源码
	const char* vertex_shader_source =
		"#version 330 core\n"
		"layout (location = 0) in vec3 vPos;\n"			// 位置变量的属性位置值为0
		"layout (location = 1) in vec2 vTexture;\n"		// 纹理变量的属性位置值为1
		"out vec4 vColor;\n"							// 输出4维颜色向量
		"out vec2 myTexture;\n"							// 输出2维纹理向量
		"out vec3 FragPos;\n"		
		"out vec3 Normal;\n"							// 光照
		"uniform mat4 transform;\n"
		"uniform vec4 color;\n"
		"uniform mat4 projection;\n"
		"void main()\n"
		"{\n"
		"    gl_Position = transform * vec4(vPos, 1.0);\n"
		"    vColor = color;\n"
		"    myTexture = vTexture;\n"
		"}\n\0";

	const char* fragment_shader_source =
		"#version 330 core\n"
		"in vec4 vColor;\n"			// 输入的颜色向量
		"in vec3 Normal;\n"			// 输入的法向量
		"in vec3 FragPos;\n"			// 输入的片段位置向量
		"in vec2 myTexture;\n"		// 输入的纹理向量
		"out vec4 FragColor;\n"		// 输出的颜色向量
		"uniform vec3 lightPos;\n"
		"uniform vec3 lightColor;\n"
		"uniform sampler2D tex;\n"
		"void main()\n"
		"{\n"
		"    FragColor = texture(tex, myTexture) * vColor;\n"	// 顶点颜色和纹理混合
		"}\n\0";

	// 生成并编译着色器
	// 顶点着色器
	int success;
	char info_log[512];
	int vertex_shader = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(vertex_shader, 1, &vertex_shader_source, NULL);
	glCompileShader(vertex_shader);
	// 检查着色器是否成功编译，如果编译失败，打印错误信息
	glGetShaderiv(vertex_shader, GL_COMPILE_STATUS, &success);
	if (!success)
	{
		glGetShaderInfoLog(vertex_shader, 512, NULL, info_log);
		std::cout << "ERROR::SHADER::VERTEX::COMPILATION_FAILED\n" << info_log << std::endl;
	}
	// 片段着色器
	int fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(fragment_shader, 1, &fragment_shader_source, NULL);
	glCompileShader(fragment_shader);
	// 检查着色器是否成功编译，如果编译失败，打印错误信息
	glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, &success);
	if (!success)
	{
		glGetShaderInfoLog(fragment_shader, 512, NULL, info_log);
		std::cout << "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n" << info_log << std::endl;
	}
	// 链接顶点和片段着色器至一个着色器程序
	shader_program = glCreateProgram();
	glAttachShader(shader_program, vertex_shader);
	glAttachShader(shader_program, fragment_shader);
	glLinkProgram(shader_program);
	// 检查着色器是否成功链接，如果链接失败，打印错误信息
	glGetProgramiv(shader_program, GL_LINK_STATUS, &success);
	if (!success) {
		glGetProgramInfoLog(shader_program, 512, NULL, info_log);
		std::cout << "ERROR::SHADER::PROGRAM::LINKING_FAILED\n" << info_log << std::endl;
	}

	// 删除着色器
	glDeleteShader(vertex_shader);
	glDeleteShader(fragment_shader);

	// 使用着色器程序
	glUseProgram(shader_program);
}

void initial(void)
{

	// 生成球的顶点
	generateBallVerticles(sphereVertices);

	// 生成球的顶点索引
	generateBallIndices(sphereIndices);

	//生成太阳光源
	vmath::vec3 lightPos(0.0f, 3.0f, 0.0f);
	glUniform3fv(glGetUniformLocation(shader_program, "lightPos"), 1, &lightPos[0]);

	// 生成并绑定球体的VAO和VBO
	glGenVertexArrays(1, &vertex_array_object);
	glGenBuffers(1, &vertex_buffer_object);
	glBindVertexArray(vertex_array_object);
	glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer_object);

	// 将顶点数据绑定至当前默认的缓冲中
	glBufferData(GL_ARRAY_BUFFER, sphereVertices.size() * sizeof(float), &sphereVertices[0], GL_STATIC_DRAW);

	// 生成并绑定EBO
	glGenBuffers(1, &element_buffer_object);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, element_buffer_object);

	// 将数据绑定至缓冲
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sphereIndices.size() * sizeof(int), &sphereIndices[0], GL_STATIC_DRAW);

	// 设置顶点属性指针 <ID>, <num>, GL_FLOAT, GL_FALSE, <offset>, <begin>
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
	glEnableVertexAttribArray(0);
	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));
	glEnableVertexAttribArray(1);

	// 创建纹理对象并加载纹理
	loadAllTextures();

	// 编写并编译着色器程序
	editAndCompileShaderProgram();

	// 设定点线面的属性
	glPointSize(3);	// 设置点的大小
	glLineWidth(1);	// 设置线宽

	// opengl属性
	glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);	// 指定多边形模式为填充
	glEnable(GL_DEPTH_TEST);	// 启用深度测试

}

void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
	switch (key)
	{
	case GLFW_KEY_ESCAPE:
		glfwSetWindowShouldClose(window, GL_TRUE);	// 关闭窗口
		break;
	case GLFW_KEY_1:
		glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);	// 线框模式
		break;
	case GLFW_KEY_2:
		glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);	// 填充模式
		break;
	case GLFW_KEY_3:
		glEnable(GL_CULL_FACE);						// 打开背面剔除
		glCullFace(GL_BACK);						// 剔除多边形的背面
		break;
	case GLFW_KEY_4:
		glDisable(GL_CULL_FACE);					// 关闭背面剔除
		break;
	default:
		break;
	}
}

void Draw(void)
{
	// 清空颜色缓冲
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	unsigned int transformLoc = glGetUniformLocation(shader_program, "transform");
	unsigned int colorLoc = glGetUniformLocation(shader_program, "color");
	// 设置纹理单元的值




	GLfloat vColor[3][4] = {
		{ 1.0f, 1.0f, 1.0f, 1.0f },
		{ 1.0f, 1.0f, 1.0f, 1.0f },
		{ 1.0f, 1.0f, 1.0f, 1.0f } };


	// 绑定VAO
	glBindVertexArray(vertex_array_object);

	vmath::mat4 view, projection, trans;


	{
		view = vmath::lookat(vmath::vec3(0.0, 3.0, 0.0), vmath::vec3(0.0, 0.0, -10.0), vmath::vec3(0.0, 1.0, 0.0));
		projection = vmath::perspective(fovy, aspact, znear, zfar);
		trans = projection * view;
	}


	// 画太阳
	{

		glUniform1i(glGetUniformLocation(shader_program, "tex"), 0);  

		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, texture_buffer_object_sun);

		trans *= vmath::translate(0.0f, 0.0f, -10.0f);
		vmath::mat4 trans_sun = trans * vmath::rotate(0.0f, vmath::vec3(0.0f, 1.0f, 0.0f));	
		glUniformMatrix4fv(transformLoc, 1, GL_FALSE, trans_sun);
		glUniform4fv(colorLoc, 1, vColor[0]);
		glDrawElements(GL_TRIANGLES, X_SEGMENTS * Y_SEGMENTS * 6, GL_UNSIGNED_INT, 0);	// 绘制三角形
	}

	// 画地球
	{
		glUniform1i(glGetUniformLocation(shader_program, "tex"), 1);  // 地球纹理单元为1
		glActiveTexture(GL_TEXTURE1);
		glBindTexture(GL_TEXTURE_2D, texture_buffer_object_earth);
		float a_earth = 6.0f;	
		float b_earth = 6.0f;	
		float x_earth = a_earth * cosf(aspect * (float)PI / 180.0f);
		float y_earth = b_earth * sinf(aspect * (float)PI / 180.0f);



		trans *= vmath::translate(-x_earth, 0.0f, y_earth);	
		vmath::mat4 trans_earth = trans * vmath::rotate(aspect, vmath::vec3(0.0f, 1.0f, 0.0f));	
		trans_earth *= vmath::scale(0.6f);	// 缩放
		glUniformMatrix4fv(transformLoc, 1, GL_FALSE, trans_earth);
		glUniform4fv(colorLoc, 1, vColor[1]);
		glDrawElements(GL_TRIANGLES, X_SEGMENTS * Y_SEGMENTS * 6, GL_UNSIGNED_INT, 0);
	}

	// 画月球
	{
		glUniform1i(glGetUniformLocation(shader_program, "tex"), 2);  // 月球纹理单元为2
		glActiveTexture(GL_TEXTURE2);
		glBindTexture(GL_TEXTURE_2D, texture_buffer_object_moon);

		trans *= vmath::rotate(aspect*12, vmath::vec3(sqrtf(2.0) / 2.0f, sqrtf(2.0) / 2.0f, 0.0f));
		trans *= vmath::translate(0.0f, 0.0f, 1.5f);	
		vmath::mat4 trans_moon = trans * vmath::rotate(0.0f, vmath::vec3(0.0f, 1.0f, 0.0f));
		trans_moon *= vmath::scale(0.6f * 0.5f);	// 缩放
		glUniformMatrix4fv(transformLoc, 1, GL_FALSE, trans_moon);
		glUniform4fv(colorLoc, 1, vColor[2]);
		glDrawElements(GL_TRIANGLES, X_SEGMENTS * Y_SEGMENTS * 6, GL_UNSIGNED_INT, 0);
	}

	// 解除绑定
	glBindVertexArray(0);

}

void reshaper(GLFWwindow* window, int width, int height)
{
	glViewport(0, 0, width, height);
	if (height == 0)
	{
		aspact = (float)width;
	}
	else
	{
		aspact = (float)width / (float)height;
	}

}

int main()
{

	glfwInit(); // 初始化GLFW

	// OpenGL版本为3.3，主次版本号均设为3
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);

	// 使用核心模式(无需向后兼容性)
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	// 创建窗口(宽、高、窗口名称)
	GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "Sphere", NULL, NULL);

	if (window == NULL)
	{
		std::cout << "Failed to Create OpenGL Context" << std::endl;
		glfwTerminate();
		return -1;
	}

	// 将窗口的上下文设置为当前线程的主上下文
	glfwMakeContextCurrent(window);

	// 初始化GLAD，加载OpenGL函数指针地址的函数
	if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
	{
		std::cout << "Failed to initialize GLAD" << std::endl;
		return -1;
	}

	initial();

	//窗口大小改变时调用reshaper函数
	glfwSetFramebufferSizeCallback(window, reshaper);

	//窗口中有键盘操作时调用key_callback函数
	glfwSetKeyCallback(window, key_callback);

	std::cout << "数字键1，2设置多边形模式为线模式和填充模式。" << std::endl;
	std::cout << "数字键3打开剔除模式并且剔除多边形的背面。" << std::endl;
	std::cout << "数字键4关闭剔除模式。" << std::endl;

	while (!glfwWindowShouldClose(window))
	{
		aspect += 1.2;
		if (aspect >= 365)
			aspect = 0;
		Draw();
		Sleep(33.3);
		glfwSwapBuffers(window);
		glfwPollEvents();
	}

	// 解绑和删除VAO和VBO
	glBindVertexArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glDeleteVertexArrays(1, &vertex_array_object);
	glDeleteBuffers(1, &vertex_buffer_object);

	//解绑并删除纹理
	glBindTexture(GL_TEXTURE_2D, 0);
	glDeleteTextures(1, &texture_buffer_object_sun);

	glfwDestroyWindow(window);

	glfwTerminate();
	return 0;
}

```)
