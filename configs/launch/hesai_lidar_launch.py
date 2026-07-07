import os
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    desktop_dir = os.environ.get('DESKTOP_DIR', os.path.expanduser('~/Desktop'))
    rviz_config = os.path.join(
        desktop_dir,
        '3D-Lidar',
        'src',
        'HesaiLidar_General_ROS-ROS2',
        'rviz2',
        'default.rviz')

    return LaunchDescription([
        Node(
            package ='hesai_lidar',
            namespace ='hesai',
            executable ='hesai_lidar_node',
            name ='hesai_node',
            output ="screen",
            parameters=[
                {"pcap_file": ""},
                {"server_ip"  : "192.168.1.201"},
                {"lidar_recv_port"  : 2368},
                {"gps_port"  : 10110},
                {"start_angle"  : 0.0},
                {"lidar_type"  : "PandarXT-32"},
                {"frame_id"  : "PandarXT-32"},
                {"pcldata_type"  : 0},
                {"publish_type"  : "both"},
                {"timestamp_type"  : ""},
                {"data_type"  : ""},
                {"lidar_correction_file"  : "$(find hesai_lidar)/config/PandarXT-32.csv"},
                {"multicast_ip"  : ""},
                {"coordinate_correction_flag"  : False},
                {"fixed_frame"  : ""},
                {"target_frame_frame"  : ""}
            ]
        ),

        Node(
            package='rviz2',
            executable='rviz2',
            name='rviz2',
            arguments=['-d', rviz_config],
            output='screen'),

    ])


