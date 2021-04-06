#include <linux/kernel.h>
#include <linux/module.h>

int init_module(void)
{
	printk("On module load: Hello world 1.\n");

	// A non 0 return means init_module failed; module can't be loaded.
	return 0;
}

void cleanup_module(void)
{
	printk("On module exit: Goodbye world 1.\n");
}  

MODULE_LICENSE("GPL");


