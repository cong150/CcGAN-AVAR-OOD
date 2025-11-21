"""
准备UTKFace OOD实验的数据集
从UTKFace数据集中划分ID和OOD区域
"""

import h5py
import numpy as np
import argparse
import os
from tqdm import tqdm

def prepare_ood_split(data_path, output_path, train_min, train_max, test_min, test_max, 
                      ood_samples_per_label=None, seed=2025):
    """
    准备OOD实验的数据划分
    
    Args:
        data_path: 原始UTKFace数据集路径
        output_path: 输出路径
        train_min: 训练集最小年龄
        train_max: 训练集最大年龄
        test_min: 测试集最小年龄
        test_max: 测试集最大年龄
        ood_samples_per_label: OOD区域每个年龄保留的样本数（None表示全部）
        seed: 随机种子
    """
    np.random.seed(seed)
    
    print(f"\n{'='*80}")
    print(f"准备UTKFace OOD数据划分:")
    print(f"  训练区域 (ID): [{train_min}, {train_max}]岁")
    print(f"  测试区域 (OOD): [{test_min}, {test_max}]岁")
    if ood_samples_per_label:
        print(f"  OOD区域每个年龄样本数: {ood_samples_per_label}")
    print(f"{'='*80}\n")
    
    # 读取原始数据
    with h5py.File(data_path, 'r') as hf:
        images = hf['images'][:]
        labels = hf['labels'][:].astype(float)
        print(f"加载数据: {images.shape}, 标签范围: [{labels.min():.1f}, {labels.max():.1f}]岁")
    
    # ID区域（训练集）
    id_mask = (labels >= train_min) & (labels <= train_max)
    id_images = images[id_mask]
    id_labels = labels[id_mask]
    print(f"\nID区域 [{train_min}, {train_max}]岁: {id_images.shape[0]} 样本")
    
    # OOD区域（测试集）
    ood_mask = (labels >= test_min) & (labels <= test_max)
    ood_images = images[ood_mask]
    ood_labels = labels[ood_mask]
    print(f"OOD区域 [{test_min}, {test_max}]岁: {ood_images.shape[0]} 样本")
    
    # 如果指定了OOD样本数限制，进行采样
    if ood_samples_per_label is not None:
        unique_labels = np.unique(ood_labels)
        selected_indices = []
        
        for label in unique_labels:
            label_indices = np.where(ood_labels == label)[0]
            if len(label_indices) > ood_samples_per_label:
                selected = np.random.choice(label_indices, ood_samples_per_label, replace=False)
            else:
                selected = label_indices
            selected_indices.extend(selected)
        
        selected_indices = np.array(selected_indices)
        ood_images = ood_images[selected_indices]
        ood_labels = ood_labels[selected_indices]
        print(f"  -> 采样后OOD样本数: {ood_images.shape[0]}")
    
    # 保存
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with h5py.File(output_path, 'w') as hf:
        # ID数据
        hf.create_dataset('id_images', data=id_images)
        hf.create_dataset('id_labels', data=id_labels)
        
        # OOD数据
        hf.create_dataset('ood_images', data=ood_images)
        hf.create_dataset('ood_labels', data=ood_labels)
        
        # 完整数据（用于oracle-full）
        hf.create_dataset('all_images', data=images)
        hf.create_dataset('all_labels', data=labels)
        
        # 元数据
        hf.attrs['train_min'] = train_min
        hf.attrs['train_max'] = train_max
        hf.attrs['test_min'] = test_min
        hf.attrs['test_max'] = test_max
        hf.attrs['id_samples'] = id_images.shape[0]
        hf.attrs['ood_samples'] = ood_images.shape[0]
    
    print(f"\n保存到: {output_path}")
    print(f"{'='*80}\n")
    
    # 统计信息
    print("标签分布统计:")
    print(f"  ID区域 - 唯一年龄数: {len(np.unique(id_labels))}")
    print(f"  OOD区域 - 唯一年龄数: {len(np.unique(ood_labels))}")
    
    return output_path


def visualize_data_split(output_path, save_fig_path=None):
    """可视化数据划分"""
    import matplotlib.pyplot as plt
    
    with h5py.File(output_path, 'r') as hf:
        id_labels = hf['id_labels'][:]
        ood_labels = hf['ood_labels'][:]
        train_min = hf.attrs['train_min']
        train_max = hf.attrs['train_max']
    
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))
    
    # ID分布
    ax1.hist(id_labels, bins=50, alpha=0.7, color='blue', edgecolor='black')
    ax1.set_xlabel('Age (years)')
    ax1.set_ylabel('Number of Samples')
    ax1.set_title(f'ID Region [{train_min}, {train_max}] years - Training Data')
    ax1.grid(True, alpha=0.3)
    
    # OOD分布
    ax2.hist(ood_labels, bins=50, alpha=0.7, color='red', edgecolor='black')
    ax2.set_xlabel('Age (years)')
    ax2.set_ylabel('Number of Samples')
    ax2.set_title(f'OOD Region - Test Data')
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    if save_fig_path:
        plt.savefig(save_fig_path, dpi=150, bbox_inches='tight')
        print(f"保存可视化图到: {save_fig_path}")
    else:
        plt.show()


def create_mixed_training_set(data_path, output_path, id_min, id_max, ood_min, ood_max, 
                              ood_samples_per_label, seed=2025):
    """
    创建混合训练集：ID区域全部数据 + OOD区域少量数据
    
    Args:
        data_path: 原始数据路径
        output_path: 输出路径
        id_min, id_max: ID区域范围
        ood_min, ood_max: OOD区域范围
        ood_samples_per_label: OOD区域每个年龄的样本数
    """
    np.random.seed(seed)
    
    print(f"\n{'='*80}")
    print("创建UTKFace混合训练集:")
    print(f"  ID区域 (全部数据): [{id_min}, {id_max}]岁")
    print(f"  OOD区域 (少量数据): [{ood_min}, {ood_max}]岁, 每年龄{ood_samples_per_label}张")
    print(f"{'='*80}\n")
    
    # 读取原始数据
    with h5py.File(data_path, 'r') as hf:
        images_all = hf['images'][:]
        labels_all = hf['labels'][:].astype(float)
        indx_train = hf['indx_train'][:]
        print(f"加载完整数据集: {images_all.shape}")
    
    # 只使用训练集索引
    images_all = images_all[indx_train]
    labels_all = labels_all[indx_train]
    
    # ID区域：全部数据
    id_mask = (labels_all >= id_min) & (labels_all <= id_max)
    id_images = images_all[id_mask]
    id_labels = labels_all[id_mask]
    print(f"✓ ID区域 [{id_min}, {id_max}]岁: {len(id_images)} 张（全部）")
    
    # OOD区域：每个年龄限制数量
    ood_mask = (labels_all > ood_min) & (labels_all <= ood_max)
    ood_images_all = images_all[ood_mask]
    ood_labels_all = labels_all[ood_mask]
    
    unique_ood_labels = np.unique(ood_labels_all)
    selected_indices = []
    
    for label in unique_ood_labels:
        label_indices = np.where(ood_labels_all == label)[0]
        if len(label_indices) > ood_samples_per_label:
            selected = np.random.choice(label_indices, ood_samples_per_label, replace=False)
        else:
            selected = label_indices
        selected_indices.extend(selected)
    
    selected_indices = np.array(selected_indices)
    ood_images = ood_images_all[selected_indices]
    ood_labels = ood_labels_all[selected_indices]
    print(f"✓ OOD区域 [{ood_min}, {ood_max}]岁: {len(ood_images)} 张（采样后）")
    
    # 合并ID和OOD数据
    mixed_images = np.concatenate([id_images, ood_images], axis=0)
    mixed_labels = np.concatenate([id_labels, ood_labels])
    
    print(f"\n✓ 混合训练集总计: {len(mixed_images)} 张")
    print(f"  - ID: {len(id_images)} 张")
    print(f"  - OOD: {len(ood_images)} 张")
    
    # 保存（格式与原始数据集一致）
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with h5py.File(output_path, 'w') as hf:
        hf.create_dataset('images', data=mixed_images)
        hf.create_dataset('labels', data=mixed_labels)
        # 创建全部索引（因为我们已经筛选好了）
        hf.create_dataset('indx_train', data=np.arange(len(mixed_images)))
        
        # 保存元数据
        hf.attrs['id_min'] = id_min
        hf.attrs['id_max'] = id_max
        hf.attrs['ood_min'] = ood_min
        hf.attrs['ood_max'] = ood_max
        hf.attrs['ood_samples_per_label'] = ood_samples_per_label
        hf.attrs['num_id_samples'] = len(id_images)
        hf.attrs['num_ood_samples'] = len(ood_images)
        hf.attrs['total_samples'] = len(mixed_images)
    
    print(f"\n✓ 保存到: {output_path}")
    print(f"{'='*80}\n")
    
    return output_path


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--data_path', type=str, required=True, 
                       help='原始UTKFace数据集路径 (h5文件)')
    parser.add_argument('--output_path', type=str, required=True,
                       help='输出路径')
    parser.add_argument('--mode', type=str, default='split', choices=['split', 'mixed'],
                       help='split: 分离ID/OOD用于分析; mixed: 创建混合训练集')
    
    # For split mode
    parser.add_argument('--train_min', type=float, default=1.0)
    parser.add_argument('--train_max', type=float, default=30.0)
    parser.add_argument('--test_min', type=float, default=30.0)
    parser.add_argument('--test_max', type=float, default=60.0)
    
    # For mixed mode  
    parser.add_argument('--id_min', type=float, default=1.0)
    parser.add_argument('--id_max', type=float, default=30.0)
    parser.add_argument('--ood_min', type=float, default=30.0)
    parser.add_argument('--ood_max', type=float, default=60.0)
    
    parser.add_argument('--ood_samples_per_label', type=int, default=5,
                       help='OOD区域每个年龄的样本数限制')
    parser.add_argument('--visualize', action='store_true',
                       help='是否生成可视化图')
    parser.add_argument('--seed', type=int, default=2025)
    
    args = parser.parse_args()
    
    if args.mode == 'split':
        # 原有功能：分离ID/OOD用于分析
        output_path = prepare_ood_split(
            data_path=args.data_path,
            output_path=args.output_path,
            train_min=args.train_min,
            train_max=args.train_max,
            test_min=args.test_min,
            test_max=args.test_max,
            ood_samples_per_label=args.ood_samples_per_label,
            seed=args.seed
        )
    else:
        # 新功能：创建混合训练集
        output_path = create_mixed_training_set(
            data_path=args.data_path,
            output_path=args.output_path,
            id_min=args.id_min,
            id_max=args.id_max,
            ood_min=args.ood_min,
            ood_max=args.ood_max,
            ood_samples_per_label=args.ood_samples_per_label,
            seed=args.seed
        )
    
    if args.visualize and args.mode == 'split':
        fig_path = output_path.replace('.h5', '_distribution.png')
        visualize_data_split(output_path, fig_path)

