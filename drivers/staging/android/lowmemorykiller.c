/* drivers/misc/lowmemorykiller.c
 *
 * Copyright (C) 2007-2008 Google, Inc.
 *
 * This software is licensed under the terms of the GNU General Public
 * License version 2, as published by the Free Software Foundation, and
 * may be copied, distributed, and modified under those terms.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/mm.h>
#include <linux/oom.h>
#include <linux/sched.h>

<<<<<<< HEAD:drivers/staging/android/lowmemorykiller.c
static int lowmem_shrink(int nr_to_scan, gfp_t gfp_mask);

static struct shrinker lowmem_shrinker = {
	.shrink = lowmem_shrink,
	.seeks = DEFAULT_SEEKS * 16
};
static uint32_t lowmem_debug_level = 1;
=======
#define DEBUG_LEVEL_DEATHPENDING 6

static uint32_t lowmem_debug_level = 2;
>>>>>>> 12394c9... Update low memory killer from .32 (By Decad3nce):drivers/staging/android/lowmemorykiller.c
static int lowmem_adj[6] = {
	0,
	1,
	6,
	12,
};
static int lowmem_adj_size = 4;
static size_t lowmem_minfree[6] = {
	3*512, // 6MB
	2*1024, // 8MB
	4*1024, // 16MB
	16*1024, // 64MB
};
static int lowmem_minfree_size = 4;
static int lowmem_file_free = 23500;

<<<<<<< HEAD:drivers/staging/android/lowmemorykiller.c
#define lowmem_print(level, x...) do { if(lowmem_debug_level >= (level)) printk(x); } while(0)

module_param_named(cost, lowmem_shrinker.seeks, int, S_IRUGO | S_IWUSR);
module_param_array_named(adj, lowmem_adj, int, &lowmem_adj_size, S_IRUGO | S_IWUSR);
module_param_array_named(minfree, lowmem_minfree, uint, &lowmem_minfree_size, S_IRUGO | S_IWUSR);
module_param_named(debug_level, lowmem_debug_level, uint, S_IRUGO | S_IWUSR);
// module_param_named(filefree, lowmem_file_free, int, S_IRUGO | S_IWUSR);
=======
static size_t lowmem_minfile[6] = {
	1536,
	2048,
	4096,
	5120,
	5632,
	6144
};
static int lowmem_minfile_size = 6;

static int ignore_lowmem_deathpending;
static struct task_struct *lowmem_deathpending;

static uint32_t lowmem_check_filepages = 0;

static uint32_t lowmem_deathpending_retries = 0;

static uint32_t lowmem_max_deathpending_retries = 1000;

#define lowmem_print(level, x...)			\
	do {						\
		if (lowmem_debug_level >= (level))	\
			printk(x);			\
	} while (0)

static int
task_notify_func(struct notifier_block *self, unsigned long val, void *data);

static struct notifier_block task_nb = {
	.notifier_call	= task_notify_func,
};

static int
task_notify_func(struct notifier_block *self, unsigned long val, void *data)
{
	struct task_struct *task = data;
	if (task == lowmem_deathpending) {
		lowmem_deathpending = NULL;
		task_free_unregister(&task_nb);
		lowmem_print(2, "deathpending end %d (%s)\n",
			task->pid, task->comm);
	}
	return NOTIFY_OK;
}
>>>>>>> 12394c9... Update low memory killer from .32 (By Decad3nce):drivers/staging/android/lowmemorykiller.c

static void dump_deathpending(struct task_struct *t_deathpending)
{
	struct task_struct *p;

	if (lowmem_debug_level < DEBUG_LEVEL_DEATHPENDING)
		return;

	BUG_ON(!t_deathpending);
	lowmem_print(DEBUG_LEVEL_DEATHPENDING, "deathpending %d (%s)\n",
		t_deathpending->pid, t_deathpending->comm);

	read_lock(&tasklist_lock);
	for_each_process(p) {
		struct mm_struct *mm;
		struct signal_struct *sig;
		int oom_adj;
		int tasksize;

		task_lock(p);
		mm = p->mm;
		sig = p->signal;
		if (!mm || !sig) {
			task_unlock(p);
			continue;
		}
		oom_adj = sig->oom_adj;
		tasksize = get_mm_rss(mm);
		task_unlock(p);
		lowmem_print(DEBUG_LEVEL_DEATHPENDING,
			"  %d (%s), adj %d, size %d\n",
			p->pid, p->comm,
			oom_adj, tasksize);
	}
	read_unlock(&tasklist_lock);
}

static int lowmem_shrink(int nr_to_scan, gfp_t gfp_mask)
{
	struct task_struct *p;
	struct task_struct *selected = NULL;
	int rem = 0;
	int tasksize;
	int i;
	int min_adj = OOM_ADJUST_MAX + 1;
	int selected_tasksize = 0;
	int array_size = ARRAY_SIZE(lowmem_adj);
	int other_free = global_page_state(NR_FREE_PAGES);
<<<<<<< HEAD:drivers/staging/android/lowmemorykiller.c
	/* hs0501.yang Changed criterion of LMK 
	 * Sometimes, the difference of nr_file_pages and sum of active and inactive file is
	 *  too big, so it's better to use sum of active & inactive file instead of nr_free_pages.
	 */
	//	int other_file = global_page_state(NR_FILE_PAGES);
	int other_file = global_page_state(NR_INACTIVE_FILE) + global_page_state(NR_ACTIVE_FILE);
=======
	int other_file = global_page_state(NR_FILE_PAGES);
	int lru_file = global_page_state(NR_ACTIVE_FILE) +
			global_page_state(NR_INACTIVE_FILE);

	/*
	 * If we already have a death outstanding, then
	 * bail out right away; indicating to vmscan
	 * that we have nothing further to offer on
	 * this pass.
	 *
	 */
	if (lowmem_deathpending) {
		dump_deathpending(lowmem_deathpending);
		if (lowmem_deathpending_retries++ < lowmem_max_deathpending_retries)
			return 0;
		else
			task_free_unregister(&task_nb);
	}
>>>>>>> 12394c9... Update low memory killer from .32 (By Decad3nce):drivers/staging/android/lowmemorykiller.c

	if(lowmem_adj_size < array_size)
		array_size = lowmem_adj_size;

	if(lowmem_minfree_size < array_size)
		array_size = lowmem_minfree_size;
<<<<<<< HEAD:drivers/staging/android/lowmemorykiller.c

	for(i = 0; i < array_size; i++) {
//		if (other_free < lowmem_minfree[i] && 
//			other_file < lowmem_minfree[i])
		if ((other_free + other_file) < lowmem_minfree[i])
		{
			min_adj = lowmem_adj[i];
			break;
=======
	for (i = 0; i < array_size; i++) {
		if (other_free < lowmem_minfree[i]) {
			if(other_file < lowmem_minfree[i] ||
				(lowmem_check_filepages &&
				(lru_file < lowmem_minfile[i]))) {

				min_adj = lowmem_adj[i];
				break;
			}
>>>>>>> 12394c9... Update low memory killer from .32 (By Decad3nce):drivers/staging/android/lowmemorykiller.c
		}
	}
	if(nr_to_scan > 0)
		lowmem_print(3, "lowmem_shrink %d, %x, ofree %d %d, ma %d\n", nr_to_scan, gfp_mask, other_free, other_file, min_adj);
	rem = global_page_state(NR_ACTIVE_ANON) +
		global_page_state(NR_ACTIVE_FILE) +
		global_page_state(NR_INACTIVE_ANON) +
		global_page_state(NR_INACTIVE_FILE);
	if (nr_to_scan <= 0 || min_adj == OOM_ADJUST_MAX + 1) {
		lowmem_print(5, "lowmem_shrink %d, %x, return %d\n", nr_to_scan, gfp_mask, rem);
		return rem;
	}

	read_lock(&tasklist_lock);
	for_each_process(p) {
<<<<<<< HEAD:drivers/staging/android/lowmemorykiller.c
		if (p->oomkilladj < min_adj || !p->mm)
=======
		struct mm_struct *mm;
		struct signal_struct *sig;
		int oom_adj;

		if (p == lowmem_deathpending) {
			lowmem_print(2, "skip death pending task %d (%s)\n",
							p->pid, p->comm);
			continue;
		}

		task_lock(p);
		mm = p->mm;
		sig = p->signal;
		if (!mm || !sig) {
			task_unlock(p);
			continue;
		}
		oom_adj = sig->oom_adj;
		if (oom_adj < min_adj) {
			task_unlock(p);
>>>>>>> 12394c9... Update low memory killer from .32 (By Decad3nce):drivers/staging/android/lowmemorykiller.c
			continue;
		tasksize = get_mm_rss(p->mm);
		if (tasksize <= 0)
			continue;
		if (selected) {
			if (p->oomkilladj < selected->oomkilladj)
				continue;
			if (p->oomkilladj == selected->oomkilladj &&
			    tasksize <= selected_tasksize)
				continue;
		}
		selected = p;
		selected_tasksize = tasksize;
		lowmem_print(2, "select %d (%s), adj %d, size %d, to kill\n",
		             p->pid, p->comm, p->oomkilladj, tasksize);
	}
	if(selected != NULL) {
		lowmem_print(1, "send sigkill to %d (%s), adj %d, size %d\n",
<<<<<<< HEAD:drivers/staging/android/lowmemorykiller.c
		             selected->pid, selected->comm,
		             selected->oomkilladj, selected_tasksize);
		force_sig(SIGKILL, selected);
		rem -= selected_tasksize;
	}
	lowmem_print(4, "lowmem_shrink %d, %x, return %d\n", nr_to_scan, gfp_mask, rem);
=======
			     selected->pid, selected->comm,
			     selected_oom_adj, selected_tasksize);
		if (!ignore_lowmem_deathpending) {
			lowmem_deathpending = selected;
			lowmem_deathpending_retries = 0;
			task_free_register(&task_nb);
		}
		force_sig(SIGKILL, selected);
		rem -= selected_tasksize;
	}
	else {
		lowmem_deathpending = NULL;
	}

	lowmem_print(4, "lowmem_shrink %d, %x, return %d\n",
		     nr_to_scan, gfp_mask, rem);
>>>>>>> 12394c9... Update low memory killer from .32 (By Decad3nce):drivers/staging/android/lowmemorykiller.c
	read_unlock(&tasklist_lock);
	return rem;
}

static int __init lowmem_init(void)
{
	register_shrinker(&lowmem_shrinker);
	return 0;
}

static void __exit lowmem_exit(void)
{
	unregister_shrinker(&lowmem_shrinker);
}

<<<<<<< HEAD:drivers/staging/android/lowmemorykiller.c
=======
module_param_named(cost, lowmem_shrinker.seeks, int, S_IRUGO | S_IWUSR);
module_param_array_named(adj, lowmem_adj, int, &lowmem_adj_size,
			 S_IRUGO | S_IWUSR);
module_param_array_named(minfree, lowmem_minfree, uint, &lowmem_minfree_size,
			 S_IRUGO | S_IWUSR);
module_param_named(debug_level, lowmem_debug_level, uint, S_IRUGO | S_IWUSR);

module_param_named(check_filepages , lowmem_check_filepages, uint,
		   S_IRUGO | S_IWUSR);
module_param_array_named(minfile, lowmem_minfile, uint, &lowmem_minfile_size,
			 S_IRUGO | S_IWUSR);
module_param_named(ignore_deathpending, ignore_lowmem_deathpending, int,
			 S_IRUGO | S_IWUSR);

module_param_named(max_deathpending_retries, lowmem_max_deathpending_retries, int,
			 S_IRUGO | S_IWUSR);

>>>>>>> 12394c9... Update low memory killer from .32 (By Decad3nce):drivers/staging/android/lowmemorykiller.c
module_init(lowmem_init);
module_exit(lowmem_exit);

MODULE_LICENSE("GPL");

